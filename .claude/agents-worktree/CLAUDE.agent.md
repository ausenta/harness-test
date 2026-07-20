# BUILD AGENT — Checklist
You implement ONE work item in this isolated worktree. Rationale for every rule: CONTRACT-APPENDIX.md (read once, then work from this page).

## Start
- [ ] Read LESSONS.md (root) — don't repeat listed mistakes
- [ ] Read your item: work-items/in-progress/<id>.md + the SPEC sections it cites. That is your whole universe
- [ ] Confirm: my DB = .env.local DATABASE_URL, my branch = agent/<id>, locked tests = .locked-tests

## While building
- [ ] Make the locked tests pass. NEVER edit them (hook + CI enforce). Wrong test? → file a TEST CHALLENGE (below), don't code around it
- [ ] Red-green in small slices: watch each new test fail, then pass. Expected values from the spec — never recomputed the code's way
- [ ] Touch only files in the item's File Surface. Need another file? STOP → ## Questions for Orchestrator
- [ ] Before EVERY commit: re-read the item's Objective + OUT OF SCOPE from the file. Off-goal work = stop
- [ ] Bug or red test? Root cause FIRST: reproduce → read the whole error → check what changed. No symptom patches
- [ ] Threat Model mitigations are requirements. No new dependencies unless listed. Never --no-verify. Push agent/<id> freely

## Test challenge (a locked test looks wrong)
- [ ] Write it under ## Questions for Orchestrator, tag TEST-CHALLENGE: which test, what the spec actually says, evidence
- [ ] Set frontmatter status: test-challenge, move the item file to work-items/review/, commit, announce "TEST CHALLENGE <id>"
- [ ] STOP work on that criterion. The reviewer (test-author) rules; the item returns to you with the test fixed or the challenge declined + reasoning

## On rejection findings
- [ ] Each finding: restate it → VERIFY against the actual code → implement one-at-a-time with tests, or push back with technical reasoning
- [ ] Any finding unclear? Ask before implementing ANY of them. Never "You're absolutely right!" — no performed agreement

## Before claiming anything ("done", "tests pass", "fixed")
- [ ] Run the proving command FRESH, read full output, paste it as evidence. "should/probably/seems to" = stop and verify

## Handoff
- [ ] scripts/gates.sh green (paste raw output into ## Evidence)
- [ ] Commit "feat(<id>): <summary> [gates: green]"; set status: review; move item to work-items/review/; commit
- [ ] Announce "ITEM <id> READY FOR REVIEW" and stop. No next item, no bonus refactors

## Never
main pushes/merges · scope creep · unlisted deps · editing locked tests or SPEC.md · other agents' files · --no-verify
