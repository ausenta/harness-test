---
id: WI-000
title: 
status: backlog        # backlog | in-progress | review | approved | rejected
branch: agent/WI-000
worktree: 
db: 
issue:                # GitHub issue number
pr:                   # GitHub PR number
spec-refs: []          # e.g. [SPEC §3.2, SPEC §5.1]
db-migration: false
dast: false            # true = API-facing; ZAP baseline runs in gates (set TARGET_URL)    # true = serialized, never parallel; forces risk-tier full
risk-tier: full        # trivial | lite | full — set at /breakdown; auth/crypto/rbac/db => always full
break-glass: false
grilled:              # true | skipped — board/grill status at approval
board-chair-verdict:  # concur | concur-with-conditions | dissent (+ overridden-by-human if so)
slop-grade:           # A–F from slop-reviewer
approved-by:          # human sign-off recorded at merge
approved-at:
depends-on: []         # item IDs that must merge first
estimate: 0.5d
---

# WI-000 — <title>

## Objective
One paragraph. What exists when this is done, per the cited spec sections.

## In Scope
- 

## OUT OF SCOPE (hard fence)
- 

## File Surface (only files the agent may touch)
- 

## Seams Under Test (public interfaces where locked acceptance tests live — declared here, confirmed nowhere else)
- e.g. `POST /api/risks` HTTP contract; `RiskService.escalate()` public signature

## Acceptance Criteria (each must map to a spec-ref)
1. [ ] ... (SPEC §x.x)
2. [ ] ... (SPEC §x.x)

## Test Plan (executed verbatim by agent, re-run by orchestrator)
1. 
2. 

## Threat Model (orchestrator fills at /breakdown — REQUIRED for full-tier)
| Threat (STRIDE) | Attack path via this change | Mitigation required in this item |
|---|---|---|
|  |  |  |

## Security Requirements
- [ ] Input validation on all new endpoints/params
- [ ] AuthZ check enforced per SPEC RBAC matrix
- [ ] No secrets in code/config; env vars only
- [ ] Parameterized queries / ORM only — no string-built SQL
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
