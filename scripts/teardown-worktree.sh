#!/usr/bin/env bash
# After APPROVE + merge: remove worktree, branch, and agent DB.
set -euo pipefail
ITEM="${1:?Usage: teardown-worktree.sh <ITEM-ID>}"
git worktree remove "../wt-${ITEM}" --force || true
git branch -D "agent/${ITEM}" || true
docker rm -f "db-${ITEM}" 2>/dev/null || true      # Strategy A
# dropdb "app_${ITEM//-/_}" || true                # Strategy B
echo "Torn down: ${ITEM}"
