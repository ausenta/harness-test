---
id: WI-H2
title: Single source of truth for gate tool versions + version-skew policy
status: backlog        # backlog | in-progress | review | approved | rejected
branch: agent/WI-H2
worktree:
db:
issue:                # GitHub issue number
pr:                   # GitHub PR number
spec-refs: [HARNESS]   # infra item — no product spec; harness supply-chain governance
db-migration: false
dast: false
risk-tier: full        # touches the security gate config in both CI and local; re-confirm tier at /breakdown
break-glass: false
grilled:
board-chair-verdict:
slop-grade:
approved-by:
approved-at:
depends-on: [WI-H1]    # build on corrected pins; also collides on workflow file surface — never dispatch concurrently with WI-H1
estimate: 0.5d
---

# WI-H2 — Single source of truth for gate tool versions + version-skew policy

## Objective
Gate tool versions are currently declared in two independent places — `scripts/gates.sh` / the local toolchain, and the CI workflow — with no mechanism keeping them equal. Observed skew: gitleaks (CI 8.9.0 vs local 8.30.1, fixed in WI-H1) and checkov (CI 3.3.8 vs local 3.3.0, still open). Skew means CI and local gates can reach different verdicts, defeating the "orchestrator independently re-runs the same gates" guarantee. This item establishes ONE canonical version manifest consumed by both CI and local gates, plus a written policy for how versions are bumped and verified.

## DECISION REQUIRED (open before dispatch)
The mechanism is a genuine choice, not a guess — raise as a GitHub `decision` issue at /breakdown and resolve before dispatch:
- Manifest format/location: e.g. `scripts/gate-versions.env` (sourced by gates.sh and the workflow) vs `.tool-versions` (asdf/mise) vs a lockfile.
- Which direction is authoritative when they differ, and who owns bumps.
- Whether `scripts/doctor.sh` should hard-fail on local-vs-manifest drift.

## In Scope
- Introduce a single canonical versions manifest.
- Refactor both workflow files and `scripts/gates.sh` to read tool versions from it (no hardcoded versions elsewhere).
- Resolve the checkov skew as part of adopting the single source.
- Document the bump/verify procedure (GETTING-STARTED.md) and, if the decision says so, add a doctor.sh drift check.

## OUT OF SCOPE (hard fence)
- Adding/removing which tools or rulesets run in the gate.
- The sha256 verification and the gitleaks pin correction — those are WI-H1 (this item consumes the corrected values).
- Any product/app code.

## File Surface (only files the agent may touch)
- scripts/gate-versions.env   (new — or the format chosen by the decision issue)
- .github/workflows/gates.yml
- .github-workflows-gates.yml   (root mirror — must stay byte-identical)
- scripts/gates.sh
- scripts/doctor.sh            (only if the decision adds a drift check)
- GETTING-STARTED.md

## Seams Under Test (public interfaces where locked acceptance tests live — declared here, confirmed nowhere else)
- The version-resolution contract: CI workflow and `scripts/gates.sh` both resolve every gate tool version from the single manifest.

## Acceptance Criteria (each must map to a spec-ref)
1. [ ] Exactly one file declares gate tool versions; grep finds no tool version literal in gates.sh or either workflow file outside the manifest (HARNESS)
2. [ ] CI workflow and local gates.sh both install/verify the versions named in the manifest (HARNESS)
3. [ ] checkov skew resolved: CI and local resolve to the same checkov version via the manifest (HARNESS)
4. [ ] Bump procedure documented in GETTING-STARTED.md; if decided, doctor.sh fails on local-vs-manifest drift (HARNESS)
5. [ ] Both workflow files byte-identical; workflow + job name stay `gates` (HARNESS)

## Test Plan (executed verbatim by agent, re-run by orchestrator)
1. `grep -rnE '(gitleaks|trivy|semgrep|checkov).*[0-9]+\.[0-9]+\.[0-9]+' scripts/gates.sh .github/workflows/gates.yml` → no version literals (only manifest references).
2. Change one version in the manifest → both CI and local gates reflect it; `scripts/doctor.sh` flags drift if that check was adopted.
3. `diff -q` the two workflow files → identical.

## Threat Model (orchestrator fills at /breakdown — REQUIRED for full-tier)
| Threat (STRIDE) | Attack path via this change | Mitigation required in this item |
|---|---|---|
| Repudiation / false assurance | CI and local pin different scanner versions → one misses a finding the other would catch; a merge passes CI while local would have blocked it | Single manifest both consume (AC1–AC3); optional doctor drift check (AC4) |
| Tampering | A version bump edits one place and not the other, quietly widening skew again | Grep-enforced no-literals-outside-manifest invariant (AC1) |

## Security Requirements
- [ ] No secrets in code/config; env vars only
- [ ] Gates green: audit, gitleaks, semgrep (evidence below)

## New Dependencies (must be pre-approved here or none)
- none (asdf/mise only if the decision issue explicitly selects it)

---
## Evidence (agent fills — raw gate output)

## Implementation Notes (agent fills)

## Questions for Orchestrator (agent fills if blocked)

## Review Findings (orchestrator fills — post judge-pass, with resolution status on re-review)

## Board Packet (orchestrator fills at docketing: recommendation, kept/dropped findings, slop grade, proposed grill questions)

## Rejection (orchestrator fills if rejected)
