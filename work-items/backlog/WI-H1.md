---
id: WI-H1
title: Align CI gate tool pins with local + sha256-verify tarball installs
status: backlog        # backlog | in-progress | review | approved | rejected
branch: agent/WI-H1
worktree:
db:
issue:                # GitHub issue number
pr:                   # GitHub PR number
spec-refs: [HARNESS]   # infra item — no product spec; harness supply-chain hardening
db-migration: false
dast: false
risk-tier: full        # auto-escalated: modifies the security gate's tool-install (supply-chain surface)
break-glass: false
grilled:
board-chair-verdict:
slop-grade:
approved-by:
approved-at:
depends-on: []
estimate: 0.5d
---

# WI-H1 — Align CI gate tool pins with local + sha256-verify tarball installs

## Objective
The hardened CI gates workflow (commit 48f9983) pins gitleaks to `8.9.0` — a lexical-sort error; the intended/current-local version is `8.30.1`, so CI has been running an older scanner than local gates. The tarball installs (gitleaks, trivy) download release assets over the network with no integrity check despite the "verified paths" comment. This item corrects the version pins to match the locally verified toolchain and adds sha256 verification so a tampered or wrong asset fails the build.

## In Scope
- Correct the gitleaks pin `8.9.0 → 8.30.1` in both workflow files.
- Add a pinned sha256 checksum for each downloaded tarball (gitleaks, trivy) and verify before `install`; mismatch = hard fail.
- Keep pins already matching local as-is (trivy 0.72.0, semgrep 1.170.0 already match).

## OUT OF SCOPE (hard fence)
- The systemic single-source-of-truth mechanism and version-skew policy — that is WI-H2.
- The checkov pin discrepancy (CI 3.3.8 vs local 3.3.0) — resolve under WI-H2's policy, not here.
- Any change to scripts/gates.sh logic or to which tools/rulesets run.
- Bumping tool versions beyond aligning to the already-installed local versions.

## File Surface (only files the agent may touch)
- .github/workflows/gates.yml
- .github-workflows-gates.yml   (root mirror — must stay byte-identical)

## Seams Under Test (public interfaces where locked acceptance tests live — declared here, confirmed nowhere else)
- The `gates` GitHub Actions workflow: tool-install step behavior (version + integrity).

## Acceptance Criteria (each must map to a spec-ref)
1. [ ] Both workflow files pin gitleaks `8.30.1` (matches local `gitleaks version 8.30.1`) (HARNESS)
2. [ ] Each tarball download (gitleaks, trivy) is verified against a pinned sha256 before install; a mismatch fails the job non-zero (HARNESS)
3. [ ] The two workflow files remain byte-identical; workflow + job name stay `gates` so the required status check still reports (HARNESS)
4. [ ] semgrep `p/github-actions` + `p/secrets` on both files: 0 findings (HARNESS)

## Test Plan (executed verbatim by agent, re-run by orchestrator)
1. `diff -q .github/workflows/gates.yml .github-workflows-gates.yml` → identical.
2. `grep -n 'GITLEAKS_V=' .github/workflows/gates.yml` → `8.30.1`.
3. Simulate a bad asset (edit the expected sha256) and confirm the verify step exits non-zero.
4. `semgrep --config p/github-actions --config p/secrets --error <both files>` → 0 findings.

## Threat Model (orchestrator fills at /breakdown — REQUIRED for full-tier)
| Threat (STRIDE) | Attack path via this change | Mitigation required in this item |
|---|---|---|
| Tampering | Release asset replaced upstream or MITM'd during CI download → malicious gitleaks/trivy binary runs with CI privileges | Pinned sha256 verified before `install`; mismatch fails the build (AC2) |
| Repudiation / false assurance | Wrong version pin (8.9.0) silently runs an older scanner missing detections → gates pass while a leak/vuln slips through | Align pin to the verified local version 8.30.1 (AC1) |

## Security Requirements
- [ ] No secrets in code/config; env vars only
- [ ] Gates green: audit, gitleaks, semgrep (evidence below)

## New Dependencies (must be pre-approved here or none)
- none

---
## Evidence (agent fills — raw gate output)

## Implementation Notes (agent fills)

## Questions for Orchestrator (agent fills if blocked)

## Review Findings (orchestrator fills — post judge-pass, with resolution status on re-review)

## Board Packet (orchestrator fills at docketing: recommendation, kept/dropped findings, slop grade, proposed grill questions)

## Rejection (orchestrator fills if rejected)
