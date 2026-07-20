# Multi-Agent Workstream Kit (Claude Code)

Orchestrator + parallel build agents with branch and database isolation, security-gated handoffs, and an approval gate before anything touches `main`.

```
                    ┌─ orchestrator (main repo, main branch) ─┐
   spec/SPEC.md ──► │ /breakdown → work-items/backlog/        │
                    │ /dispatch  → provisions agent           │
                    │ /review    → scope + spec + gates check │──► merge → push
                    └───────────────┬─────────────────────────┘
              ┌─────────────────────┼─────────────────────┐
        wt-WI-001              wt-WI-002              wt-WI-003
        agent/WI-001           agent/WI-002           agent/WI-003
        db-WI-001 (own DB)     db-WI-002              db-WI-003
        gates.sh must be green before handoff to work-items/review/
```

## Install into your repo
1. Copy `CLAUDE.md`, `.claude/`, `work-items/`, `scripts/` into the repo root. `chmod +x scripts/*.sh`.
2. Drop your spec markdown at `spec/SPEC.md`.
3. Edit `scripts/gates.sh` for your stack (npm vs pytest, etc.) and pick a DB strategy in `scripts/new-agent-worktree.sh` (Docker Postgres per agent is default; SQLite and shared-server options are inline).
4. Install gate tooling once: `gitleaks`, `semgrep`, `trivy`, `checkov` (all fail-closed if missing), Docker for ZAP baseline scans. Then `git config core.hooksPath scripts/git-hooks` (done automatically on first dispatch).

## Run sequence (current — see WORKFLOW.md for the full map)
1. `claude` in repo root → orchestrator session. `gh auth login` once.
2. `/breakdown` — SPEC.md → traced, tiered, seam-declared vertical-slice items + GitHub Issues + wave plan; foggy areas become decision issues for you.
3. `/dispatch WI-001` per wave item — worktree + branch + isolated DB, test-author commits locked red skeletons, draft PR opens, CI starts.
4. One terminal per agent: `cd ../wt-WI-001 && claude` → "read CLAUDE.md and execute your work item." Agents run in parallel; their job is making the locked tests pass, gates green, evidence pasted.
5. `/review WI-001` — independent re-verify, tiered parallel reviewers, judge pass, board packet filed to `board/` and the PR. Pipeline keeps flowing; dispatch the next item.
6. `/board` when you sit down — docket, chair-led grills, your approve/reject/defer per item; approvals squash-merge via PR in dependency order, rejections return to the queue as rework, rulings become ADRs.

## v8 — operations (council remediation; final version before first run)
- **Agent monitor** (`scripts/agent-monitor.sh`): flags DEAD (worktree gone) and STALLED (no commits or file activity for STALL_MINUTES, default 60) agents plus down DB containers, with recovery guidance — work is never lost, it lives on the branch. Run on a timer while agents work.
- **Doctor + install guide**: `scripts/doctor.sh` red/greens the entire toolchain, auth, hooks, CI, and branch protection in seconds; `GETTING-STARTED.md` is the step-by-step zero-to-first-merge path ending in the WI-000 wall-clocked dry run.
- **Rulebook → checklist**: the agent contract is now a one-page checkbox CLAUDE.md; all rationale moved to CONTRACT-APPENDIX.md (read once).
- **Test-challenge flow**: an agent that believes a locked test is wrong files a TEST CHALLENGE and stops; the test-author (reviewer of tests) rules on spec evidence — upheld challenges get the locked test amended, declined ones get written reasoning — and the item always returns to the queue to finish. Challenges are answered same-session; dissent is now as cheap as compliance.
- **Worked example**: `examples/WI-000-example.md` shows a completed item end-to-end (the shape to copy); `examples/WI-000-starter.md` is the dry-run item itself.

## v7 — hardening from ECC (cherry-picked)
- **Defense baseline in every subagent**: reviewers take no orders from reviewed material — embedded directives in diffs/comments/items are reported as critical integrity findings; secrets encountered are redacted, never echoed.
- **Silent-failure hunting**: the code-quality reviewer now explicitly hunts swallowed errors, empty catches, ignored return codes, and masking fallbacks — a failure the operator never sees is worse than a crash.
- **LESSONS.md**: recurring agent mistakes become one-line rules (second occurrence = lesson), read at breakdown, dispatch, and agent session start; pruned when they stop firing.

## v6 — engineering discipline (adapted from mattpocock/skills and obra/superpowers)
- **Seams + vertical slices**: breakdown declares each item's public seams; locked skeletons are acceptance-level tests at those seams only, and the build agent works red-green in tracer-bullet slices inside them — fixing the horizontal-slicing risk in pure test-first. Tautological assertions (expected value recomputed the way the code computes it) are banned by name for both test-author and reviewers.
- **Fowler smell baseline**: the code-quality reviewer carries twelve named smells with fixes, bound by three rules — repo standards override, skip what tooling enforces, always a judgement call.
- **Domain model**: CONTEXT.md glossary maintained at breakdown, terminology-drift findings at review, and every board ruling recorded as an ADR in docs/adr/ — grills leave documents behind, not just verdicts. Foggy spec areas become GitHub decision issues, never guesses.
- **Verification before completion**: agents may not claim any status without running the proving command fresh and pasting the output; "should/probably/seems to" is a stop signal, and board packets carry evidence per claim.
- **Receiving findings like an engineer**: on rework, agents verify each finding against the codebase before implementing, push back with technical reasoning when a finding is wrong, never perform agreement, and never partially implement an unclear batch.
- **Debugging iron law**: no fixes without root-cause investigation — reproduction, full error reading, recent-change check, boundary instrumentation — enforced hardest exactly when skipping is most tempting.

## v5 — test-first dispatch + GitHub as system of record
- **Test-first**: at dispatch, an independent test-author subagent writes failing test skeletons from the acceptance criteria and threat-model mitigations; they're committed red and locked (`.locked-tests`, enforced by pre-commit AND CI). The build agent makes them pass without touching them — author of "correct" and author of "code" are now different minds. Agents may add tests, never amend locked ones.
- **GitHub tracking end to end**: every work item is an Issue (labeled tier/wave), every agent branch is a draft PR from minute one, every push runs the gates workflow in Actions (build history in Checks), review findings and board packets post as PR comments, rejections as change-request reviews, approvals as PR reviews, merges via `gh pr merge --squash`, chair dissent-overrides as labeled comments. Install `.github-workflows-gates.yml` at `.github/workflows/gates.yml` and set branch protection: gates check required + 1 review.

## v4 — the review board (async human-in-the-loop)
- New queue state `board/`: reviewed items dock there awaiting the human; the pipeline keeps flowing — freed agents immediately pull the next backlog item, and rejected items return to the queue as `-r2` rework reusing their branch and worktree.
- `/board` convenes a batched session over the docket. An independent **board-chair** subagent with fresh context conducts each grill — it audits the orchestrator's recommendation before questioning the human, and goes on record with CONCUR / CONDITIONS / DISSENT. Dissents overridden by the human land in `BOARD_MINUTES.log`.
- Stale-branch protection: approving an item after main has moved triggers rebase + full independent re-verify before merge.
- Docketed-but-unmerged branches count in file-surface collision checks so parallel dispatches can't silently conflict with work awaiting sign-off.

## v3 — security depth
- **Pre-commit enforcement**: every commit in every worktree runs staged secrets scanning (gitleaks protect), diff-aware SAST, and env/key-file blocking in seconds. `--no-verify` is denied at the agent permission level and treated as an integrity violation.
- **Threat modeling at breakdown**: full-tier items get a STRIDE walk before code exists; each modeled mitigation becomes an acceptance criterion, and the security reviewer flags any unmitigated modeled threat as critical (`threat-model-gap`).
- **Curated SAST**: semgrep runs owasp-top-ten + security-audit + secrets + stack packs instead of `--config auto`.
- **IaC + container scanning**: `trivy fs`/`trivy config` and `checkov` cover Dockerfiles, Bicep/Terraform, and K8s manifests (checkov auto-skips when no IaC present).
- **Conditional DAST**: items flagged `dast: true` run a ZAP baseline scan against the app on the agent's isolated DB.

## v2 — review orchestration (patterns adapted from Cloudflare's AI code review system)
- **Specialist reviewers, not one big prompt**: four subagents in `.claude/agents/` (spec-compliance, code-quality, security, performance), each with an explicit "what NOT to flag" fence and a structured critical/warning/suggestion output format. They run in parallel during `/review`.
- **Risk tiers**: items are classified trivial/lite/full at `/breakdown`; tier controls how many reviewers spawn. Auth/crypto/RBAC/migration surfaces always escalate to full.
- **Judge pass**: the orchestrator deduplicates, re-categorizes, and reasonableness-filters findings — and verifies uncertain ones against source before counting them.
- **Decision rubric with approval bias**: suggestions and isolated warnings still merge (with comments); only criticals and warning-patterns block.
- **Noise-filtered shared context**: `verify-item.sh` strips lockfiles/minified/vendored files (migrations always kept) and writes one `review-context/<item>/context.md` + per-file patches that all reviewers read from disk — no diff duplication across prompts.
- **Incremental re-reviews**: fixed findings drop, unfixed re-emit, "won't fix" justifications get evaluated rather than silently dropped.
- **Break glass**: human-only override that merges anyway but logs the outstanding findings to `BREAK_GLASS.log`.
- **Prompt-injection hygiene**: agent-authored text (evidence, notes, commits) is treated as data; embedded directives to the orchestrator are a critical integrity finding.

## Guarantees by construction
- **No crossover**: git worktrees give each agent a physically separate checkout on its own branch; provisioning writes a unique `DATABASE_URL` per worktree.
- **Grilled, not rubber-stamped**: `/grill-me` interrogates the human with diff-specific questions before their approve counts (mandatory on full-tier and migrations), and `/stopaislop` embeds an AI-slop audit (grade A–F) in every review — a D/F grade withdraws the approve recommendation outright.
- **Human sign-off on every merge**: the orchestrator's rubric produces a recommendation only; nothing merges to main without an explicit human `approve <item-id>`, recorded in the item's frontmatter. Rejections need no sign-off — blocking is always safe.
- **No agent pushes**: agent-side `.claude/settings.json` denies push/merge to main at the permission and hook level; only the orchestrator merges.
- **No scope creep**: items carry a hard OUT OF SCOPE fence and a declared file surface; review diffs the branch against that surface and rejects anything outside it.
- **No trust-me testing**: agents paste raw gate evidence, and the orchestrator re-runs all gates independently before approval.

Requires the GitHub CLI (`gh auth login`) in the orchestrator environment.

Docs for the underlying Claude Code features (worktrees, hooks, settings, slash commands): https://docs.claude.com/en/docs/claude-code/overview
