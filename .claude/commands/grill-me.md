Grill the human on work item $ARGUMENTS before they sign the merge (single-item path; /board is the batch path). Spawn the **board-chair** subagent to conduct it — never grill as yourself, orchestrator: you wrote the recommendation and cannot independently challenge it.

Preconditions: item is in review/ with a RECOMMEND APPROVE verdict. If not, say so and stop.

## Output format

**Part 1 — STOPAISLOP REPORT.** Run the slop-reviewer (via /stopaislop $ARGUMENTS if not already run this review cycle) and print the report first. If grade is D/F, say plainly that you are withdrawing the approve recommendation and stop the grill — there's nothing to sign.

**Part 2 — THE GRILL.** Ask the human 3–5 pointed questions they should be able to answer before approving. Draw from the actual diff and findings, not generic checklists. Pick the hardest applicable ones:
- Which SPEC requirement does this item close out, and what's still open in that section?
- This diff changed <specific risky thing — RBAC rule, SLA calc, migration, auth path>. What breaks downstream if it's wrong?
- The judge pass dropped <n> findings as speculative. Here's the most borderline one — do you agree it's noise?
- What's the rollback if this is wrong in production — revert-safe or does the migration make it one-way?
- Reviewer X flagged <warning> and we're merging anyway. Own that call?

## Rules
- Wait for real answers. One-word replies to substantive questions get one follow-up push-back, then their call stands — they're the human, you're the gate-keeper of informedness, not the decision.
- If their answers reveal a misunderstanding of what the change does, correct it with diff citations before accepting an approve.
- If an answer surfaces a genuine new concern, convert it to a finding, re-run the rubric, and update the recommendation.
- When the grill is done, record `grilled: true` + date in the item frontmatter, then re-present the merge recommendation and await `approve $ARGUMENTS` / `reject $ARGUMENTS <reason>` as normal.
- The human can skip with "skip grill" — record `grilled: skipped`. Full-tier and db-migration items: note the skip in BREAK_GLASS.log-style fashion in the item file so the audit trail shows an unexamined approval.
