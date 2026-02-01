#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STATE_DIR="$ROOT/runtime/checkpoint/state"
REPORT="$ROOT/reports/phase33B-rolling.txt"

IR="$ROOT/world-ir/build/room.ir.json"
BASE_SNAPSHOT="$ROOT/runtime/world/snapshots/room.snapshot.json"
TRACE_FULL="$STATE_DIR/rolling.trace.jsonl"

mkdir -p "$STATE_DIR" "$ROOT/reports"

bash "$ROOT/runtime/world/load-ir.sh" "$IR" >/dev/null

cat > "$TRACE_FULL" <<EV
{"type":"ENTITY_CREATE","id":"roll-001","owner":"valid:userA","actor":"valid:userA"}
{"type":"COMPONENT_ATTACH","entity":"roll-001","component":"tag","data":{"label":"ok"},"actor":"valid:userA"}
{"type":"ZONE_MOVE","entity":"roll-001","zone":"zone-a","actor":"valid:userA"}
{"type":"COMPONENT_UPDATE","entity":"roll-001","component":"tag","patch":{"label":"ok2"},"actor":"valid:userA"}
EV

CK_DIR="$STATE_DIR/ck"
rm -rf "$CK_DIR"
mkdir -p "$CK_DIR"

ck1=$(python3 "$ROOT/runtime/checkpoint/rolling-checkpoint.py" zone-a "$BASE_SNAPSHOT" "$TRACE_FULL" "$CK_DIR" ck1)
ck2=$(python3 "$ROOT/runtime/checkpoint/rolling-checkpoint.py" zone-a "$BASE_SNAPSHOT" "$TRACE_FULL" "$CK_DIR" ck2)
ck3=$(python3 "$ROOT/runtime/checkpoint/rolling-checkpoint.py" zone-a "$BASE_SNAPSHOT" "$TRACE_FULL" "$CK_DIR" ck3)

# prune to 2
pruned=$(python3 "$ROOT/runtime/checkpoint/prune.py" "$CK_DIR" 2)

# window replay on subset (first two events)
WIN_SNAP="$STATE_DIR/window.snapshot.json"
win_hash=$(python3 "$ROOT/runtime/checkpoint/window-replay.py" "$BASE_SNAPSHOT" "$TRACE_FULL" 0 1 "$WIN_SNAP")

# full replay hash
FULL_SNAP="$STATE_DIR/full.snapshot.json"
full_hash=$(python3 "$ROOT/runtime/world/apply-event.py" "$BASE_SNAPSHOT" "$TRACE_FULL" "$FULL_SNAP")

remaining=$(ls "$CK_DIR" | grep -c checkpoint.json || true)

{
  echo "# Phase 33B — Rolling Checkpoints"
  echo "Date: $(date -Iseconds)"
  echo "IR: $IR"
  echo "Checkpoint Dir: $CK_DIR"
  echo "Remaining Checkpoints: $remaining"
  echo "Prune Result: $pruned"
  if [ "$remaining" = "2" ]; then
    echo "PASS: prune retention"
  else
    echo "FAIL: prune retention"
  fi
  echo "Window Hash: $win_hash"
  echo "Full Hash: $full_hash"
  if [ "$win_hash" != "$full_hash" ]; then
    echo "PASS: window replay produces partial state"
  else
    echo "FAIL: window replay" 
  fi
} > "$REPORT"

sed -n '1,200p' "$REPORT"

if [ "$remaining" != "2" ]; then
  exit 1
fi
if [ "$win_hash" = "$full_hash" ]; then
  exit 1
fi
