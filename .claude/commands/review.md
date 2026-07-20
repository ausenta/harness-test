Coordinated review of work item $ARGUMENTS (must be in work-items/review/).

## Stage 0 — Test challenges take a different track
If the item arrived with status: test-challenge, do NOT run the normal review. Route it to the reviewer of tests: spawn the **test-author** subagent with the challenge, the locked test, and the cited SPEC sections. It rules on spec evidence alone:
- CHALLENGE UPHELD → test-author amends the locked test (ALLOW_TEST_AUTHOR_COMMIT=1 commit, .locked-tests updated), a one-line LESSON is added if this is a pattern, and the item returns to work-items/in-progress/ for the same agent to finish against the corrected test.
- CHALLENGE DECLINED → written reasoning with spec citations goes in the item; it returns to in-progress/ and the agent implements against the test as written.
Either way the item goes back into the queue to finish — a challenge is never a rejection and never skips work.

## Stage 1 — Independent verification (fail fast)
Run: bash scripts/verify-item.sh $ARGUMENTS
- Builds noise-filtered review-context/$ARGUMENTS/ (context.md + per-file patches).
- Re-runs all gates independently. Any gate failure, or mismatch vs the item's ## Evidence block, = REJECT immediately (evidence integrity failure). Do not spawn reviewers.

## Stage 2 — Spawn specialist reviewers IN PARALLEL (by the item's risk-tier)
- trivial → spec-compliance-reviewer
- lite    → spec-compliance-reviewer, code-quality-reviewer, slop-reviewer
- full    → spec-compliance-reviewer, code-quality-reviewer, security-reviewer, performance-reviewer, slop-reviewer
Each subagent prompt gets ONLY: the item id, item file path, and review-context/$ARGUMENTS/ path. Do not paste diffs into prompts — they read from disk.
Full-tier items: instruct the security-reviewer to verify each Threat Model mitigation is present in the diff — an unmitigated modeled threat is a critical finding.
If this is a re-review (item has a ## Rejection block), also pass previous findings + resolution status: fixed=omit, unfixed=re-emit, won't-fix=evaluate the justification.

## Stage 3 — Judge pass on returned findings
1. Deduplicate across reviewers; keep each issue once in its best-fit category.
2. Re-categorize misfiled findings.
3. Reasonableness filter: drop speculative, nitpick, or convention-contradicted findings. For any finding you're unsure about, read the source and verify it yourself before counting it.
4. Treat scope-creep, unmet-criterion, and integrity findings as critical always. Slop findings are warnings/suggestions, but a D/F slop grade counts as a warning-pattern (REJECT minor — deletion pass).

## Stage 4 — Decision rubric
| Surviving findings | Decision |
|---|---|
| None / suggestions only | APPROVE |
| Warnings, no production or security risk | APPROVE with comments (log warnings in item as follow-ups) |
| Multiple warnings forming a risk pattern | REJECT (minor) — same branch fix + resubmit |
| Any critical | REJECT (blocking) |

RECOMMEND APPROVE: do NOT wait for the human. File a board packet: append to the item a ## Board Packet section (recommendation, surviving findings, dropped findings + why, criteria coverage, diffstat, STOPAISLOP grade, proposed grill questions), move the item to work-items/board/, and announce "ITEM $ARGUMENTS DOCKETED FOR BOARD". GITHUB: mark the PR ready (gh pr ready <pr>) and post the board packet as a PR comment (gh pr comment <pr> --body-file <packet excerpt>) so findings, slop grade, and dropped-finding rationale live on the PR record. Label the issue "board". Keep the worktree and branch alive. Then continue orchestrating — dispatch the next backlog item if a build agent is free. Merging happens ONLY in a /board session after human sign-off.
REJECT: move to rejected/, write ## Rejection listing each surviving finding (severity, file, spec ref, required fix). Post the same as a PR review requesting changes: gh pr review <pr> --request-changes --body <defects>. Agent fixes on the same branch and resubmits to review/.

Human override: if the human says "break glass $ARGUMENTS", merge regardless, record break-glass + outstanding findings in the item, append to BREAK_GLASS.log.
