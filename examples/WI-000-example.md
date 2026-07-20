# WORKED EXAMPLE — what "done" looks like
This is WI-000 as it appears in work-items/approved/ after a full pipeline pass. Copy the *shape* of this artifact: complete frontmatter, checked criteria, raw evidence, a real board packet. (Command outputs below are illustrative.)
---
id: WI-000
title: Health endpoint returning app version
status: approved
branch: agent/WI-000
worktree: ../wt-WI-000 (torn down)
db: postgresql://localhost:55217/app_WI_000 (torn down)
issue: 1
pr: 2
spec-refs: [DRY-RUN]
db-migration: false
dast: false
risk-tier: trivial
break-glass: false
grilled: true
slop-grade: A
board-chair-verdict: concur
approved-by: human
approved-at: 2026-07-20T15:42Z
estimate: 0.25d
---
## Acceptance Criteria
1. [x] GET /health returns HTTP 200 (DRY-RUN) — tests/health.test.ts::WI-000_AC1
2. [x] Body version equals config value, not a literal (DRY-RUN) — ::WI-000_AC2
## Evidence
```
$ bash scripts/gates.sh
=== GATE: Lint ===            0 errors
=== GATE: Unit tests ===      2 passed (incl. 2/2 locked), coverage new code 100%
=== GATE: Dependency audit == 0 high/critical
=== GATE: Secrets scan ===    no leaks found
=== GATE: SAST ===            0 blocking findings
=== GATE: FS + IaC (trivy) == 0 HIGH/CRITICAL
=== GATE: checkov ===         no IaC files — skipped
=== GATE: DAST ===            not flagged — skipped
ALL GATES GREEN
```
## Implementation Notes
Route reads config.version at request time. No deviations from spec. Locked skeletons untouched (see .locked-tests).
## Board Packet
Recommendation: APPROVE. Findings kept: 0. Dropped in judge pass: 1 (code-quality suggestion "extract handler" — speculative generality on a 9-line file). Criteria: 2/2 with diff citations. Slop grade A. Diffstat: 2 files, +23. Evidence per claim: gates output above re-run independently, exit 0.
## Board record
Chair verdict: CONCUR ("recommendation survives audit; dropped finding was correctly dropped"). Grill Q1: which spec requirement closes? → DRY-RUN pipeline proof. Q2: rollback? → single revert, no migration. Ruled: approve WI-000. Merged PR #2 (squash), Issue #1 closed.
