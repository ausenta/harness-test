#!/usr/bin/env bash
# Dead/stalled agent detector. Run manually, on a timer, or: watch -n 300 scripts/agent-monitor.sh
# Flags any in-progress item whose worktree has shown no activity for STALL_MINUTES (default 60).
set -uo pipefail
STALL_MINUTES="${STALL_MINUTES:-60}"
NOW=$(date +%s); ALERTS=0
printf "%-14s %-10s %-22s %s\n" "ITEM" "STATUS" "LAST ACTIVITY" "NOTE"
for f in work-items/in-progress/*.md; do
  [ -e "$f" ] || { echo "(no items in progress)"; exit 0; }
  ITEM=$(basename "$f" .md); WT="../wt-${ITEM%-r[0-9]*}"
  if [ ! -d "$WT" ]; then
    printf "%-14s %-10s %-22s %s\n" "$ITEM" "DEAD" "worktree missing" ">>> re-dispatch: /dispatch $ITEM"; ALERTS=$((ALERTS+1)); continue
  fi
  # newest of: last commit time, newest file mtime (excluding .git)
  C=$(git -C "$WT" log -1 --format=%ct 2>/dev/null || echo 0)
  F=$(find "$WT" -path "$WT/.git" -prune -o -type f -newer /dev/null -printf '%T@\n' 2>/dev/null | sort -rn | head -1 | cut -d. -f1); F=${F:-0}
  LAST=$(( C > F ? C : F )); AGE_MIN=$(( (NOW - LAST) / 60 ))
  DBSTATE=""
  docker ps --format '{{.Names}}' 2>/dev/null | grep -q "db-${ITEM%-r[0-9]*}" || DBSTATE=" DB-DOWN"
  if [ "$AGE_MIN" -ge "$STALL_MINUTES" ]; then
    printf "%-14s %-10s %-22s %s\n" "$ITEM" "STALLED" "${AGE_MIN}m ago${DBSTATE}" ">>> check session; if dead: restart in $WT (work is on the branch), or re-dispatch"
    ALERTS=$((ALERTS+1))
  else
    printf "%-14s %-10s %-22s %s\n" "$ITEM" "active" "${AGE_MIN}m ago${DBSTATE}" ""
  fi
done
echo; [ "$ALERTS" -gt 0 ] && { echo "$ALERTS agent(s) need attention. Recovery: work is never lost — it lives on the branch."; exit 1; } || echo "all agents healthy"
