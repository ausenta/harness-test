Run a slop audit on work item $ARGUMENTS (any item in review/ or in-progress/).

1. If review-context/$ARGUMENTS/ doesn't exist, run: bash scripts/verify-item.sh $ARGUMENTS (skip is fine if gates were already run; the context build is what matters).
2. Spawn the slop-reviewer subagent with the item id and review-context/$ARGUMENTS/ path.
3. Output the STOPAISLOP REPORT verbatim:

```
STOPAISLOP REPORT — $ARGUMENTS
Grade: <A–F> — <summary>
Findings: <n> (<x> warning / <y> suggestion)
<file:line> — <issue> → <fix>
...
Lines that should not exist: <count>
```

4. Disposition:
- Grade A/B → note it in the item file, no action required.
- Grade C → append findings to the item's ## Review Findings; agent cleans up before or with its next resubmission.
- Grade D/F → REJECT-worthy pattern: the agent padded its work. Add findings to ## Rejection and send back for a deletion pass. Slop never merges just because tests pass.
