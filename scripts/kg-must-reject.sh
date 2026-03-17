#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MR_DIR="$ROOT/runtime/tetragrammatron/fixtures/kg/must-reject"

for fixture in "$MR_DIR"/*.kg; do
  [[ -f "$fixture" ]] || continue
  set +e
  err="$(python3 "$ROOT/runtime/tetragrammatron/tools/kgc.py" "$fixture" 2>&1 >/dev/null)"
  status=$?
  set -e
  if [[ $status -eq 0 ]]; then
    echo "must-reject accepted invalid grammar: $fixture" >&2
    exit 1
  fi
  if ! printf '%s' "$err" | grep -Eq 'KGCError|missing|duplicate|mismatch|malformed|unknown directive'; then
    echo "must-reject unexpected error for $fixture: $err" >&2
    exit 1
  fi
done

echo "ok kg must-reject"
