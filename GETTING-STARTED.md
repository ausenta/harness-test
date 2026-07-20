# GETTING STARTED — from zero to first merged item

Do these in order. Each step ends with a check. Total time: ~30–45 minutes plus the dry run.

## Step 1 — Base toolchain
Install: **git**, **Node 20+**, **Docker Desktop** (running), **GitHub CLI (`gh`)**, **Python 3.11+** with `pipx`.
Check: `git --version && node -v && docker info && gh --version && python3 --version`

## Step 2 — Security gate tooling (gates fail-closed without these)
- gitleaks — macOS: `brew install gitleaks` · Linux: release binary from github.com/gitleaks/gitleaks
- semgrep — `pipx install semgrep`
- trivy — `brew install trivy` or the aquasecurity install script
- checkov — `pipx install checkov`
Check: `gitleaks version && semgrep --version && trivy --version && checkov --version`

## Step 3 — Copy the kit into your repo
Copy `CLAUDE.md`, `WORKFLOW.md`, `LESSONS.md`, `.claude/`, `work-items/`, `scripts/`, `examples/` into the repo root. Then:
```
chmod +x scripts/*.sh scripts/git-hooks/*
git config core.hooksPath scripts/git-hooks
```
Check: `git config core.hooksPath` prints `scripts/git-hooks`.

## Step 4 — CI workflow
```
mkdir -p .github/workflows && cp .github-workflows-gates.yml .github/workflows/gates.yml
git add . && git commit -m "chore: install multi-agent harness" && git push
```
Check: the `gates` workflow appears under the repo's Actions tab.

## Step 5 — GitHub auth + branch protection
```
gh auth login          # needs repo + workflow scopes
```
Repo → Settings → Branches → protect `main`: require the **gates** status check + **1 approving review**; disallow force pushes. Agents get no approve rights.
Check: a direct push to main from a test branch is refused.

## Step 6 — Doctor
```
bash scripts/doctor.sh
```
Check: `READY`. Fix any FAIL line top-to-bottom and re-run. Do not proceed on a failing doctor.

## Step 7 — WI-000 dry run (do this before any real spec)
A deliberately trivial toy item proves every pipe under zero stakes. `examples/WI-000-example.md` shows what the finished artifact looks like.
1. Copy `examples/WI-000-starter.md` to `work-items/backlog/WI-000.md`.
2. Start the orchestrator (`claude` in repo root) → `/dispatch WI-000`.
3. New terminal: `cd ../wt-WI-000 && claude` → "read CLAUDE.md and execute your work item."
4. When it hands off: `/review WI-000`, then `/board`, grill, `approve WI-000`.
5. **Wall-clock the whole thing.** That number is your process overhead per item; it calibrates how big the trivial tier's bypass should be.
Check: WI-000 merged to main via a squashed PR, issue closed, worktree gone, `scripts/agent-monitor.sh` reports no items.

## Step 7b — Optional: cmux flight deck (macOS)
`bash scripts/setup-cmux.sh --orchestrator` — installs the cmux terminal, wires agent Stop/Notification hooks to ring the right pane (cmux CLI → OSC escape → macOS notification fallback), and patches existing worktrees. One cmux workspace per worktree + one for the orchestrator; the sidebar shows each branch and PR status.

## Step 8 — Go
Drop your real spec at `spec/SPEC.md` → `/breakdown` → dispatch wave 1. Keep `scripts/agent-monitor.sh` on a timer (or `watch -n 300`) while agents run.

## Daily driver reference
| When | Run |
|---|---|
| Session start | `bash scripts/doctor.sh` (10s sanity) |
| Agents working | `bash scripts/agent-monitor.sh` (flags dead/stalled agents + down DBs) |
| Item ready | `/review WI-nnn` |
| You have 20 min | `/board` |
| Something's weird | doctor → monitor → the item's PR checks, in that order |
