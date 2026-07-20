#!/usr/bin/env bash
# Configure the cmux interface for a multi-agent run (app already installed).
# Builds one launchable workspace per agent + orchestrator + monitor, with named
# tabs and notification wiring, then opens them in cmux where the CLI allows.
# Usage: bash scripts/cockpit.sh          (run from repo root, any time; idempotent)
set -uo pipefail
[ "$(uname)" = "Darwin" ] || { echo "cmux is macOS-only; use tmux layout instead."; exit 1; }

echo "== 1. Notification wiring (idempotent) =="
[ -f scripts/notify.sh ] || bash scripts/setup-cmux.sh --orchestrator >/dev/null 2>&1 || true
python3 - << 'PYEOF'
import json, os
for p, ev in [('.claude/agents-worktree/settings.json', ['Notification','Stop']),
              ('.claude/settings.json', ['Notification'])]:
    s = json.load(open(p)) if os.path.exists(p) else {}
    h = s.setdefault('hooks', {})
    for e in ev:
        lst = h.setdefault(e, [])
        cmd = f"bash scripts/notify.sh {'stop' if e=='Stop' else 'attention'}"
        if not any(cmd in json.dumps(x) for x in lst):
            lst.append({"hooks":[{"type":"command","command":cmd}]})
    json.dump(s, open(p,'w'), indent=2)
print("hooks verified")
PYEOF

echo "== 2. Named launchers (tab titles = who's who) =="
# Orchestrator launcher: title, then Claude. Split suggestion printed for the monitor pane.
cat > start-orchestrator.sh << 'LEOF'
#!/usr/bin/env bash
printf '\033]0;ORCHESTRATOR · main\007'
cd "$(dirname "$0")" && exec claude
LEOF
chmod +x start-orchestrator.sh
# Monitor launcher (its own pane/tab)
cat > start-monitor.sh << 'LEOF'
#!/usr/bin/env bash
printf '\033]0;MONITOR · agents\007'
cd "$(dirname "$0")" && exec watch -n 300 bash scripts/agent-monitor.sh
LEOF
chmod +x start-monitor.sh
# Per-worktree agent launchers
COUNT=0
for wt in ../wt-*/; do
  [ -d "$wt" ] || continue
  ITEM=$(basename "$wt" | sed 's/^wt-//')
  cat > "${wt}start-agent.sh" << LEOF
#!/usr/bin/env bash
printf '\033]0;AGENT · ${ITEM}\007'
cd "\$(dirname "\$0")" && exec claude
LEOF
  chmod +x "${wt}start-agent.sh"
  mkdir -p "${wt}scripts"; cp scripts/notify.sh "${wt}scripts/notify.sh" 2>/dev/null || true
  COUNT=$((COUNT+1))
done
echo "launchers: orchestrator + monitor + ${COUNT} agent worktree(s)"

echo "== 3. Open workspaces in cmux =="
open_in_cmux() {
  if command -v cmux >/dev/null 2>&1 && cmux open "$1" >/dev/null 2>&1; then return 0; fi
  open -a cmux "$1" >/dev/null 2>&1
}
open_in_cmux "$(pwd)"
for wt in ../wt-*/; do [ -d "$wt" ] && open_in_cmux "$(cd "$wt" && pwd)"; done
echo "(if tabs didn't appear, add the folders in cmux's sidebar manually — paths below)"

echo
echo "== Cockpit layout for the multi-agent test =="
echo "  Tab 1  ORCHESTRATOR   $(pwd)              run: ./start-orchestrator.sh"
echo "         └─ split pane  MONITOR             run: ./start-monitor.sh"
for wt in ../wt-*/; do [ -d "$wt" ] && echo "  Tab    AGENT $(basename "$wt" | sed 's/wt-//')      $(cd "$wt" && pwd)   run: ./start-agent.sh"; done
echo "  Optional: split cmux's in-app browser beside any agent tab pointed at its dev server"
echo
echo "How to read it: sidebar shows each tab's branch + PR status; a BLUE RING = that agent"
echo "stopped or needs input (Cmd+Shift+U jumps to most recent). MONITOR pane catches anything"
echo "the rings miss (stalled >60m, dead worktrees, down DBs)."
echo "Re-run this script after each /dispatch to pick up new worktrees."
