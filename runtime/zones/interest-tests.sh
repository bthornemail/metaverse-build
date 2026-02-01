#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REPORT="$ROOT/reports/phase32B-interest.txt"

zones=$(python3 "$ROOT/runtime/zones/interest.py" tile-0-0 1)
count=$(printf "%s\n" "$zones" | wc -l | tr -d ' ')
first=$(printf "%s\n" "$zones" | head -n 1)
last=$(printf "%s\n" "$zones" | tail -n 1)

{
  echo "# Phase 32B — Interest Management"
  echo "Date: $(date -Iseconds)"
  echo "Center: tile-0-0"
  echo "Radius: 1"
  echo "Count: $count"
  echo "First: $first"
  echo "Last: $last"
  if [ "$count" = "9" ] && [ "$first" = "tile--1--1" ] && [ "$last" = "tile-1-1" ]; then
    echo "PASS: deterministic interest set"
  else
    echo "FAIL: deterministic interest set"
  fi
} > "$REPORT"

sed -n '1,200p' "$REPORT"

if [ "$count" != "9" ]; then
  exit 1
fi
