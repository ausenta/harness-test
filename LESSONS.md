# LESSONS.md — Recurring agent mistakes and their fixes

Maintained by the orchestrator; updated at each wave retro and whenever a rejection reveals a *pattern* (second occurrence = lesson). Read by the orchestrator at every /breakdown and /dispatch, and by build agents at session start. Keep it under ~30 entries — prune lessons that stop firing; stale lessons are context bloat.

Format: one line each — SYMPTOM → RULE.

## Lessons
<!-- example: Agents hardcode SLA day-counts instead of reading config → breakdown must cite the config key, test-author asserts against it -->
- Agent COMMITS an out-of-surface fix (e.g. hardened CI-YAML) to make its own gates pass → sync it read-only into the worktree (working-tree change, NOT a commit); raise the fix in Questions for Orchestrator; the board rebase carries the main-side fix. An agent must never commit to files that scored it green (WI-000: accepted once only because byte-identity to main was independently verified).
