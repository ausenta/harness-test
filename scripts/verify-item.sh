#!/usr/bin/env bash
# Orchestrator review helper (v2):
#   1. Noise-filtered review context (shared context file + per-file patches)
#   2. Scope check vs declared file surface
#   3. Independent gate re-run
# Usage: scripts/verify-item.sh WI-001
set -euo pipefail
ITEM="${1:?Usage: verify-item.sh <ITEM-ID>}"
BRANCH="agent/${ITEM}"
WT="../wt-${ITEM}"
ITEM_FILE="work-items/review/${ITEM}.md"
CTX="review-context/${ITEM}"

rm -rf "$CTX" && mkdir -p "$CTX/diffs"

# --- Noise filter (lockfiles, minified, maps, vendored). Migrations ALWAYS kept. ---
NOISE='(^|/)(package-lock\.json|yarn\.lock|pnpm-lock\.yaml|bun\.lock|Cargo\.lock|go\.sum|poetry\.lock|Pipfile\.lock|flake\.lock)$|\.min\.(js|css)$|\.bundle\.js$|\.map$|(^|/)(vendor|node_modules|dist|build)/'

git diff --name-only "main...${BRANCH}" | sort > "$CTX/changed-all.txt"
grep -vE "$NOISE" "$CTX/changed-all.txt" > "$CTX/changed-reviewable.txt" || true
# Re-add anything that looks like a migration even if pattern-matched as noise
grep -Ei 'migrat' "$CTX/changed-all.txt" >> "$CTX/changed-reviewable.txt" || true
sort -u -o "$CTX/changed-reviewable.txt" "$CTX/changed-reviewable.txt"

# --- Per-file patches (reviewers read only what's relevant to their domain) ---
while IFS= read -r f; do
  [ -n "$f" ] || continue
  safe=$(echo "$f" | tr '/' '__')
  git diff "main...${BRANCH}" -- "$f" > "$CTX/diffs/${safe}.patch" || true
done < "$CTX/changed-reviewable.txt"

# --- Shared context file (written once, read by every reviewer — token saver) ---
{
  echo "# Review Context: ${ITEM}"
  echo "Branch: ${BRANCH} | Worktree: ${WT}"
  echo; echo "## Work Item"; cat "$ITEM_FILE"
  echo; echo "## Changed files (post noise-filter)"; cat "$CTX/changed-reviewable.txt"
  echo; echo "## Filtered as noise"; comm -23 "$CTX/changed-all.txt" "$CTX/changed-reviewable.txt" || true
  echo; echo "## Diffstat"; git diff "main...${BRANCH}" --stat
} > "$CTX/context.md"

echo "=== SCOPE CHECK ==="
echo "Changed (all): $(wc -l < "$CTX/changed-all.txt") | Reviewable: $(wc -l < "$CTX/changed-reviewable.txt")"
echo "--- Declared file surface (${ITEM_FILE}) ---"
sed -n '/## File Surface/,/^## /p' "$ITEM_FILE" | grep '^- ' || true
echo ">>> REJECT if any file in ${CTX}/changed-all.txt is outside the declared surface"
echo "    (work-items/, CLAUDE.md, .env.local, .claude/ exempt)."

echo; echo "=== INDEPENDENT GATE RE-RUN in ${WT} ==="
( cd "$WT" && bash scripts/gates.sh )

echo; echo "=== CONTEXT READY: ${CTX}/ (context.md + diffs/) ==="
