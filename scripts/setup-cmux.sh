#!/usr/bin/env bash
# Set up cmux (manaflow-ai/cmux, macOS only) as the flight deck for this harness:
#  1. Install the cmux app
#  2. Wire agent handoffs/attention into notifications (cmux CLI if present, OSC escape fallback)
#  3. Patch agent-side Claude Code hooks so every future worktree notifies automatically
# Usage: bash scripts/setup-cmux.sh [--orchestrator]   (flag also adds hooks to this repo's session)
set -euo pipefail
[ "$(uname)" = "Darwin" ] || { echo "cmux is macOS-only. On Linux/Windows use tmux/Windows Terminal panes + scripts/agent-monitor.sh."; exit 1; }

echo "== 1. Install cmux =="
if [ -d "/Applications/cmux.app" ]; then
  echo "already installed"
elif command -v brew >/dev/null && brew info --cask cmux >/dev/null 2>&1; then
  brew install --cask cmux
else
  echo "Downloading latest release DMG..."
  TMP=$(mktemp -d)
  if command -v gh >/dev/null; then
    gh release download --repo manaflow-ai/cmux --pattern "*macos*.dmg" --dir "$TMP"
  else
    URL=$(curl -s https://api.github.com/repos/manaflow-ai/cmux/releases/latest | grep -o 'https://[^"]*macos[^"]*\.dmg' | head -1)
    curl -L "$URL" -o "$TMP/cmux.dmg"
  fi
  DMG=$(ls "$TMP"/*.dmg | head -1)
  MNT=$(hdiutil attach "$DMG" -nobrowse | awk '/\/Volumes\//{print $NF; exit}')
  cp -R "$MNT"/cmux.app /Applications/
  hdiutil detach "$MNT" >/dev/null
  echo "installed to /Applications/cmux.app"
fi

echo "== 2. Notifier helper =="
cat > scripts/notify.sh << 'NEOF'
#!/usr/bin/env bash
# Called by Claude Code hooks. Reads hook JSON on stdin; announces via cmux CLI, else OSC 777 escape
# (cmux picks up OSC 9/99/777 and rings the pane), else macOS notification, else silent.
PAYLOAD=$(cat 2>/dev/null || true)
ITEM="${WORK_ITEM:-$(basename "$PWD")}"
EVENT="${1:-attention}"
case "$EVENT" in
  stop)   TITLE="Agent idle: $ITEM"; BODY="Session finished or waiting — check for handoff/questions";;
  *)      TITLE="Agent needs you: $ITEM"; BODY=$(echo "$PAYLOAD" | grep -o '"message":"[^"]*"' | cut -d'"' -f4); BODY="${BODY:-input required}";;
esac
if command -v cmux >/dev/null 2>&1; then
  cmux notify "$TITLE" "$BODY" 2>/dev/null && exit 0
fi
# OSC 777 fallback straight to the terminal
[ -w /dev/tty ] && printf '\033]777;notify;%s;%s\007' "$TITLE" "$BODY" > /dev/tty 2>/dev/null
command -v osascript >/dev/null && osascript -e "display notification \"$BODY\" with title \"$TITLE\"" 2>/dev/null
exit 0
NEOF
chmod +x scripts/notify.sh
echo "scripts/notify.sh created"

echo "== 3. Patch agent-side hooks (.claude/agents-worktree/settings.json) =="
python3 - << 'PYEOF'
import json
p = '.claude/agents-worktree/settings.json'
s = json.load(open(p))
hooks = s.setdefault('hooks', {})
def add(event, cmd):
    lst = hooks.setdefault(event, [])
    if not any(cmd in json.dumps(e) for e in lst):
        lst.append({"hooks":[{"type":"command","command":cmd}]})
add('Notification', 'bash scripts/notify.sh attention')
add('Stop',         'bash scripts/notify.sh stop')
json.dump(s, open(p,'w'), indent=2)
print("hooks added: Notification + Stop -> scripts/notify.sh")
PYEOF

if [ "${1:-}" = "--orchestrator" ]; then
  echo "== 3b. Orchestrator session hooks (.claude/settings.json) =="
  python3 - << 'PYEOF'
import json, os
p = '.claude/settings.json'
s = json.load(open(p)) if os.path.exists(p) else {}
hooks = s.setdefault('hooks', {})
lst = hooks.setdefault('Notification', [])
cmd = 'bash scripts/notify.sh attention'
if not any(cmd in json.dumps(e) for e in lst):
    lst.append({"hooks":[{"type":"command","command":cmd}]})
json.dump(s, open(p,'w'), indent=2)
print("orchestrator Notification hook added")
PYEOF
fi

echo "== 4. Existing worktrees =="
for wt in ../wt-*/; do
  [ -d "$wt" ] || continue
  mkdir -p "$wt/.claude" "$wt/scripts"
  cp .claude/agents-worktree/settings.json "$wt/.claude/settings.json"
  cp scripts/notify.sh "$wt/scripts/notify.sh"
  echo "patched $wt"
done

echo
echo "DONE. Open cmux and add one workspace per worktree (../wt-*) plus one for this repo (orchestrator)."
echo "The sidebar shows each workspace's branch + PR status; panes ring when an agent stops or needs input."
echo "New worktrees from /dispatch inherit the hooks automatically."
