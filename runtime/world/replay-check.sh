#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TRACE_FILE="${1:-}"
SNAPSHOT_FILE="${2:-}"

if [ -z "$TRACE_FILE" ] || [ -z "$SNAPSHOT_FILE" ]; then
  echo "usage: replay-check.sh <seed.trace.jsonl> <snapshot.json>" >&2
  exit 2
fi

if [ ! -f "$TRACE_FILE" ]; then
  echo "trace not found: $TRACE_FILE" >&2
  exit 2
fi

if [ ! -f "$SNAPSHOT_FILE" ]; then
  echo "snapshot not found: $SNAPSHOT_FILE" >&2
  exit 2
fi

hash_a=$(python3 - <<PY
import json, hashlib
with open("$SNAPSHOT_FILE","r") as fh:
    data = json.load(fh)
print(hashlib.sha256(json.dumps(data,sort_keys=True,separators=(",", ":")).encode("utf-8")).hexdigest())
PY
)

REPLAY_SNAPSHOT="$ROOT/runtime/world/snapshots/replay.snapshot.json"
hash_b=$(python3 "$ROOT/runtime/world/replay.py" "$TRACE_FILE" "$REPLAY_SNAPSHOT")

REPORT="$ROOT/reports/phase26B-replay.txt"

{
  echo "# Phase 26B — Replay Determinism"
  echo "Date: $(date -Iseconds)"
  echo "Trace: $TRACE_FILE"
  echo "Snapshot: $SNAPSHOT_FILE"
  echo "Replayed: $REPLAY_SNAPSHOT"
  echo "Hash A: $hash_a"
  echo "Hash B: $hash_b"
  if [ "$hash_a" = "$hash_b" ]; then
    echo "PASS: hashes identical"
  else
    echo "FAIL: divergence"
  fi
} > "$REPORT"

sed -n '1,200p' "$REPORT"

if [ "$hash_a" != "$hash_b" ]; then
  exit 1
fi
