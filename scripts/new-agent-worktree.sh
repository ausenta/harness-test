#!/usr/bin/env bash
# Usage: scripts/new-agent-worktree.sh WI-001
# Creates: branch agent/WI-001, worktree ../wt-WI-001, isolated DB, agent env.
set -euo pipefail

ITEM="${1:?Usage: new-agent-worktree.sh <ITEM-ID>}"
BRANCH="agent/${ITEM}"
WT="../wt-${ITEM}"
DB_NAME="app_${ITEM//-/_}"   # e.g. app_WI_001

# 1. Branch + worktree off main (reused if this is a rework re-dispatch)
git fetch origin main --quiet || true
BASE_ITEM="${ITEM%-r[0-9]*}"                      # WI-001-r2 -> WI-001
if [ -d "../wt-${BASE_ITEM}" ]; then
  echo "Reusing existing worktree ../wt-${BASE_ITEM} (rework)"; WT="../wt-${BASE_ITEM}"; BRANCH="agent/${BASE_ITEM}"
else
  git worktree add -b "$BRANCH" "$WT" main
fi

# 2. Isolated database — pick ONE strategy and delete the others.

## Strategy A: Postgres in Docker, one container per agent (strongest isolation)
PORT=$(( 55000 + RANDOM % 5000 ))
docker run -d --name "db-${ITEM}" -e POSTGRES_PASSWORD=agent -e POSTGRES_DB="$DB_NAME" \
  -p "${PORT}:5432" postgres:16-alpine >/dev/null
DB_URL="postgresql://postgres:agent@localhost:${PORT}/${DB_NAME}"

## Strategy B: shared local Postgres, one database per agent
# createdb "$DB_NAME"
# DB_URL="postgresql://localhost:5432/${DB_NAME}"

## Strategy C: SQLite per worktree (simplest)
# DB_URL="file:${WT}/.agent.db"

# 3. Agent env + instructions
cat > "${WT}/.env.local" <<EOF
WORK_ITEM=${ITEM}
DATABASE_URL=${DB_URL}
EOF
cp .claude/agents-worktree/CLAUDE.agent.md "${WT}/CLAUDE.md"
cp .claude/agents-worktree/CONTRACT-APPENDIX.md "${WT}/CONTRACT-APPENDIX.md"
mkdir -p "${WT}/.claude"
cp .claude/agents-worktree/settings.json "${WT}/.claude/settings.json"   # push/merge deny-list + notify hooks
mkdir -p "${WT}/scripts" && cp scripts/notify.sh "${WT}/scripts/notify.sh" 2>/dev/null || true

# 4. Security pre-commit hook — applies to this worktree AND the main repo
git config core.hooksPath scripts/git-hooks

# 5. If the item is dast: true, agent must set TARGET_URL in .env.local and export DAST=true

# 6. Run migrations/seed so agent starts from a known schema
# (cd "$WT" && npm ci && npm run db:migrate && npm run db:seed)

echo "READY: ${ITEM}"
echo "  branch:   ${BRANCH}"
echo "  worktree: ${WT}"
echo "  db:       ${DB_URL}"
echo "  start agent:  cd ${WT} && claude"
