Dispatch work item $ARGUMENTS to a build agent (test-first).

1. Verify the item exists in work-items/backlog/ and its depends-on items are all in approved/ (board/ doesn't count — not merged yet). For rework items (-r2), reuse the existing branch/worktree.
2. Check file-surface collision against every item in in-progress/ AND board/. If collision → refuse and report, or re-sequence.
3. Read LESSONS.md; fold any lesson relevant to this item's surface into the item file as explicit constraints.
4. Provision: bash scripts/new-agent-worktree.sh $ARGUMENTS
5. TEST-FIRST: spawn the **test-author** subagent in the new worktree with the item file + cited SPEC sections. It writes failing test skeletons (one per acceptance criterion + threat-model mitigations) and pastes the red run. Then, in the worktree:
   - write the created test paths to .locked-tests
   - ALLOW_TEST_AUTHOR_COMMIT=1 git add <tests> .locked-tests && git commit -m "test($ARGUMENTS): failing skeletons [red]"
   - confirm the suite is red. If any skeleton passes on an empty tree, it tests nothing — fix before dispatch.
6. GITHUB: link the work item to its Issue (created at /breakdown; number in frontmatter). Push the branch and open a DRAFT PR:
   gh pr create --draft --title "$ARGUMENTS: <title>" --body "Closes #<issue>. Board packet to follow." --base main --head agent/$ARGUMENTS
   Record the PR number in the item frontmatter. CI (gates workflow) now tracks every push.
7. Move the item to in-progress/, set status + branch + worktree + db + issue + pr in frontmatter.
8. Tell the human: "Start the agent: cd ../wt-$ARGUMENTS && claude — say: read CLAUDE.md and execute your work item. Its job: make the locked tests pass without touching them."
