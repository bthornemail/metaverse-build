#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STATE_DIR="$ROOT/runtime/time/state"
REPORT="$ROOT/reports/phase35B-time.txt"

IR="$ROOT/world-ir/build/room.ir.json"
BASE_SNAPSHOT="$ROOT/runtime/world/snapshots/room.snapshot.json"
TRACE="$STATE_DIR/time.trace.jsonl"
CHECKPOINT="$STATE_DIR/time.checkpoint.json"
SNAPSHOT_CP="$STATE_DIR/time.snapshot.json"
TIMELINE="$STATE_DIR/timeline.json"
BRANCHED="$STATE_DIR/timeline.branch.json"
MATERIALIZED="$STATE_DIR/window.snapshot.json"

mkdir -p "$STATE_DIR" "$ROOT/reports"

bash "$ROOT/runtime/world/load-ir.sh" "$IR" >/dev/null

cat > "$TRACE" <<EV
{"type":"ENTITY_CREATE","id":"time-001","owner":"valid:userA","actor":"valid:userA"}
{"type":"COMPONENT_ATTACH","entity":"time-001","component":"tag","data":{"label":"ok"},"actor":"valid:userA"}
{"type":"COMPONENT_UPDATE","entity":"time-001","component":"tag","patch":{"label":"ok2"},"actor":"valid:userA"}
EV

# Build checkpoint
python3 "$ROOT/runtime/checkpoint/checkpoint.py" zone-a "$BASE_SNAPSHOT" "$TRACE" "$SNAPSHOT_CP" "$CHECKPOINT" >/dev/null

# Timeline object
cat > "$TIMELINE" <<JSON
{"world":"room","timeline":"main","nodes":{"ck-1":{"checkpoint":"$CHECKPOINT","parent":null}}}
JSON

# Branch
branch_id=$(python3 "$ROOT/runtime/time/branch.py" "$TIMELINE" ck-1 "$BRANCHED")

# Materialize window (first event only)
hash_window=$(python3 "$ROOT/runtime/time/materialize.py" "$CHECKPOINT" "$TRACE" 0 0 "$MATERIALIZED")

{
  echo "# Phase 35B — Time Engine"
  echo "Date: $(date -Iseconds)"
  echo "Timeline: $TIMELINE"
  echo "Branch ID: $branch_id"
  echo "Materialized Hash: $hash_window"
  if [ -n "$branch_id" ]; then
    echo "PASS: branch created"
  else
    echo "FAIL: branch created"
  fi
  if [ -n "$hash_window" ]; then
    echo "PASS: window materialized"
  else
    echo "FAIL: window materialized"
  fi
} > "$REPORT"

sed -n '1,200p' "$REPORT"

if [ -z "$branch_id" ]; then
  exit 1
fi
if [ -z "$hash_window" ]; then
  exit 1
fi
