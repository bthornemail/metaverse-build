#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REPORT="$ROOT/reports/phase32C-authority.txt"
POLICY="$ROOT/runtime/zones/authority-policy.json"

set +e
ok_out=$(python3 "$ROOT/runtime/zones/authority-check.py" "$POLICY" zone-a valid:userA 2>/dev/null)
ok_status=$?
fail_out=$(python3 "$ROOT/runtime/zones/authority-check.py" "$POLICY" zone-a valid:userB 2>&1)
fail_status=$?
set -e

{
  echo "# Phase 32C — Zone Authority Delegation"
  echo "Date: $(date -Iseconds)"
  echo "Policy: $POLICY"
  echo "OK Status: $ok_status"
  echo "OK Output: $ok_out"
  echo "FAIL Status: $fail_status"
  echo "FAIL Output: $fail_out"
  if [ "$ok_status" = "0" ] && [ "$fail_status" = "3" ]; then
    echo "PASS: zone authority enforced"
  else
    echo "FAIL: zone authority enforced"
  fi
} > "$REPORT"

sed -n '1,200p' "$REPORT"

if [ "$ok_status" != "0" ] || [ "$fail_status" != "3" ]; then
  exit 1
fi
