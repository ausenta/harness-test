#!/usr/bin/env bash
# Quality + security gates (v3). Exit non-zero on any failure.
# Run by build agents before handoff, RE-RUN independently by orchestrator.
set -uo pipefail
FAIL=0
step() { echo; echo "=== GATE: $1 ==="; }

# Curated SAST ruleset — tune packs to your stack
SEMGREP_RULES="--config p/owasp-top-ten --config p/security-audit --config p/secrets --config p/typescript --config p/react --config p/sql-injection"

step "Lint"
npm run lint || FAIL=1                          # or: ruff check .

step "Unit tests + coverage"
npm test -- --coverage || FAIL=1                # or: pytest --cov

step "Dependency audit (high/critical)"
npm audit --audit-level=high || FAIL=1          # or: pip-audit

step "Secrets scan (full tree)"
if command -v gitleaks >/dev/null; then gitleaks detect --source . --no-banner || FAIL=1
else echo "gitleaks missing — fail-closed"; FAIL=1; fi

step "SAST (semgrep, curated ruleset)"
if command -v semgrep >/dev/null; then semgrep $SEMGREP_RULES --error --quiet || FAIL=1
else echo "semgrep missing — fail-closed"; FAIL=1; fi

step "Filesystem vulns + IaC misconfig (trivy)"
if command -v trivy >/dev/null; then
  trivy fs --severity HIGH,CRITICAL --exit-code 1 --quiet . || FAIL=1
  trivy config --severity HIGH,CRITICAL --exit-code 1 --quiet . || FAIL=1   # Dockerfile, K8s, Terraform
else echo "trivy missing — fail-closed"; FAIL=1; fi

step "IaC policy scan (checkov — runs only if IaC present)"
if find . -path ./node_modules -prune -o \( -name '*.bicep' -o -name '*.tf' -o -name 'Dockerfile*' -o -name '*.yaml' -path '*k8s*' \) -print -quit | grep -q .; then
  if command -v checkov >/dev/null; then checkov -d . --quiet --compact || FAIL=1
  else echo "IaC files present but checkov missing — fail-closed"; FAIL=1; fi
else echo "no IaC files — skipped"
fi

step "DAST baseline (only if item flagged dast: true)"
if [ "${DAST:-false}" = "true" ]; then bash "$(dirname "$0")/dast-baseline.sh" || FAIL=1
else echo "not a DAST-flagged item — skipped"; fi

echo
if [ "$FAIL" -eq 0 ]; then echo "ALL GATES GREEN"; else echo "GATES FAILED — do not hand off"; fi
exit $FAIL
