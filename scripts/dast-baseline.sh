#!/usr/bin/env bash
# ZAP baseline scan for API-facing work items (item frontmatter: dast: true).
# Requires the app running against the agent's ISOLATED DB. Set TARGET_URL in .env.local.
set -euo pipefail
TARGET_URL="${TARGET_URL:?Set TARGET_URL in .env.local (e.g. http://localhost:3000)}"
# Start your app first, e.g.: npm run start:test &  (wire into your stack)
docker run --rm --network host -v "$(pwd):/zap/wrk:rw" ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py -t "$TARGET_URL" -r zap-report.html -w zap-warnings.md -m 5 -T 10
# zap-baseline exits non-zero on WARN by default; -m/-T bound the scan time.
echo "DAST report: zap-report.html"
