Convene the review board over everything in work-items/board/.

## 1. Docket
List all pending items: id, title, risk-tier, recommendation, slop grade, surviving findings count, days waiting, dependency order. Note any item whose branch is now STALE (main advanced since its review).

## 2. Per item (dependency order), for each item the human wants to hear:
a. Spawn the **board-chair** subagent (fresh context) with the packet path and review-context path. It audits the recommendation, conducts the grill, and goes on record with CONCUR / CONCUR WITH CONDITIONS / DISSENT. You (orchestrator) stay silent during the grill except to answer factual questions about the process.
b. Human rules: `approve <id>`, `reject <id> <reason>`, or `defer <id>`. Batch shorthand is allowed for trivial/lite items the human waves through: `approve <id> <id> <id>` — but full-tier and db-migration items must each pass through the chair individually.

## 3. Execute rulings
- APPROVE: if the branch is stale, first rebase agent/<id> onto main — resolving any conflict by understanding BOTH intents first (read the commit messages, PRs, and originating issues on each side; preserve both intents where possible, and where they're incompatible, the board rules which wins) — then re-run scripts/verify-item.sh <id> — a clean re-verify is required before merge (a merge that was safe against old main is not automatically safe now). Then merge via GitHub so the record lives there:
    gh pr review <pr> --approve --body "Board: approved by <human>. Chair: <verdict>."
    gh pr merge <pr> --squash --delete-branch
  Record approved-by/grilled/board-chair-verdict in frontmatter, move to approved/ (issue auto-closes via "Closes #"), teardown worktree + DB. Merge strictly in dependency order.
- REJECT: gh pr review <pr> --request-changes with the human's reason + chair's dissent; move packet to rejected/; create a rework item <id>-r2 in backlog/ scoped to the fixes. KEEP the branch and worktree — the rework dispatch reuses them (scripts/new-agent-worktree.sh skips creation if the worktree exists).
- DEFER: leave in board/; note the date.

## 4. Decisions become ADRs
Any architectural ruling made in this session — a dissent override, a conflict-resolution call, a deliberate acceptance of a warning, a change of direction — gets an ADR in docs/adr/ (NNNN-title.md: context, decision, consequences) and, where it coins or changes a term, a CONTEXT.md glossary update. A board that only produces verdicts forgets why; a board that produces ADRs compounds.

## 5. Close the session
Summarize: merged (in order), rejected (with owners of rework), deferred, chair dissents overridden by the human (these get logged in the item, in BOARD_MINUTES.log, AND as a labeled PR comment `dissent-overridden` — dissent overrides are the audit trail's most important line).
