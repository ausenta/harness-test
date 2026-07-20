#!/usr/bin/env bash
# Environment doctor — run before wave one and after any machine change. Red/green in seconds.
set -uo pipefail
PASS=0; FAIL=0
ok(){ echo "  [OK]   $1"; PASS=$((PASS+1)); }
bad(){ echo "  [FAIL] $1  ->  $2"; FAIL=$((FAIL+1)); }
have(){ command -v "$1" >/dev/null 2>&1; }
echo "== Toolchain =="
for t in git node npm docker gh python3; do have $t && ok "$t $(command $t --version 2>/dev/null | head -1)" || bad "$t missing" "see GETTING-STARTED.md step 1"; done
echo "== Security gate tooling =="
for t in gitleaks semgrep trivy checkov; do have $t && ok "$t" || bad "$t missing" "GETTING-STARTED.md step 2 (gates fail-closed without it)"; done
echo "== Services & auth =="
docker info >/dev/null 2>&1 && ok "docker daemon running" || bad "docker daemon not running" "start Docker (agent DBs + ZAP need it)"
gh auth status >/dev/null 2>&1 && ok "gh authenticated" || bad "gh not authenticated" "run: gh auth login"
echo "== Repo wiring =="
[ "$(git config core.hooksPath 2>/dev/null)" = "scripts/git-hooks" ] && ok "pre-commit hooks path set" || bad "core.hooksPath not set" "run: git config core.hooksPath scripts/git-hooks"
[ -f .github/workflows/gates.yml ] && ok "CI gates workflow installed" || bad ".github/workflows/gates.yml missing" "GETTING-STARTED.md step 4"
[ -f spec/SPEC.md ] && ok "spec/SPEC.md present" || bad "spec/SPEC.md missing" "drop your spec in (WI-000 dry run doesn't need it)"
for f in CLAUDE.md LESSONS.md work-items/TEMPLATE.md scripts/gates.sh; do [ -f "$f" ] && ok "$f" || bad "$f missing" "re-copy the kit"; done
gh api "repos/{owner}/{repo}/branches/main/protection" >/dev/null 2>&1 && ok "branch protection on main" || bad "no branch protection on main (or insufficient scope)" "GETTING-STARTED.md step 5"
echo; echo "== Result: $PASS ok, $FAIL failing =="
[ "$FAIL" -eq 0 ] && echo "READY. Next: the WI-000 dry run (GETTING-STARTED.md step 7)." || echo "Fix the FAIL lines top to bottom, then re-run."
exit $FAIL
