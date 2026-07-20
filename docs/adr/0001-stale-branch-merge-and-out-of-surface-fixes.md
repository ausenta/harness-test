# ADR-0001 — Stale-branch merges & out-of-surface harness fixes

Date: 2026-07-20
Status: Accepted
Context: /board session for WI-000 (DRY-RUN pipeline-proof item), chair CONCUR WITH CONDITIONS, ruled by human (byron.bricker).

## Context
WI-000's build branch was dispatched before two harness commits landed on `main` (`48f9983` supply-chain hardening of the gates workflow; `21e4d76` backlog items WI-H1/WI-H2). When the agent's gates were blocked by semgrep findings on the CI-YAML files — files outside WI-000's declared file surface — the agent synced `main`'s hardened version into its worktree **by committing them** to `agent/WI-000`, and its item text claimed "no out-of-surface edits." The board also found the packet's stated rollback ("single revert") was wrong: `main`'s scaffold `src/app.ts` imports `./routes/health.js`, so reverting `health.ts` alone leaves a dangling import and breaks the build.

## Decisions
1. **Stale branches are rebased at the board, not merged raw.** When `main` has advanced since an item's review, a naïve two-dot diff merge can delete files added on `main` and revert unrelated changes. Policy: rebase `agent/<id>` onto `main`, resolve conflicts by preserving both intents (read both sides' commits/PRs/issues), re-run the independent gate re-verify, and merge only via `gh pr merge --squash` (3-way) on a clean re-verify. Verified here: post-rebase net diff reduced to the deliverable only; WI-H1/WI-H2 and the hardened workflow were preserved.
2. **Agents sync out-of-surface fixes read-only, never commit them.** If a harness-level file outside an agent's surface blocks its gates, the agent raises it in `## Questions for Orchestrator`; the orchestrator fixes it on `main`; the agent may sync that fix read-only into the worktree to run green locally, but must leave it as an uncommitted working-tree change. The board rebase carries the main-side fix. An agent must never commit to a file that scored its own work green. Recorded in [[LESSONS]] and the agent contract (`.claude/agents-worktree/CONTRACT-APPENDIX.md`, item 2). This WI-000 instance was accepted **once** only because byte-identity to `main` was independently verified by the chair.
3. **WI-000 rollback requires reverting the scaffold wiring too.** Because `src/app.ts` (from the scaffold on `main`) statically imports `./routes/health.js`, a rollback of WI-000 must also revert that import or `main` will not compile. For this dry-run item the risk is **accepted** — `main` may briefly be red on a lone revert; a real rollback reverts the app wiring in the same change.
4. **The `/health` contract is locked as shipped:** `GET /health → 200 {"status":"ok","version":<config.version>}`. DRY-RUN has no product spec and nothing downstream depends on the shape, so locking it now costs nothing.

## Consequences
- Board sessions must check staleness and rebase before merging; the merge that was safe against old `main` is re-verified against current `main`.
- The agent contract now forbids committing out-of-surface files; reviewers treat such a commit as a finding unless byte-identity to `main` is proven.
- A future rollback of the health endpoint is a two-file revert (route + `app.ts` wiring), not one.
