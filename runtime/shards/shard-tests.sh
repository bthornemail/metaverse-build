#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STATE_DIR="$ROOT/runtime/shards/state"
REPORT="$ROOT/reports/phase34-shards.txt"

IR="$ROOT/world-ir/build/room.ir.json"
BASE_SNAPSHOT="$ROOT/runtime/world/snapshots/room.snapshot.json"
TRACE="$STATE_DIR/zone.trace.jsonl"
SNAPSHOT="$STATE_DIR/zone.snapshot.json"
CHECKPOINT="$STATE_DIR/zone.checkpoint.json"

mkdir -p "$STATE_DIR" "$ROOT/reports"

bash "$ROOT/runtime/world/load-ir.sh" "$IR" >/dev/null

cat > "$TRACE" <<EV
{"type":"ENTITY_CREATE","id":"shard-001","owner":"valid:userA","actor":"valid:userA"}
{"type":"COMPONENT_ATTACH","entity":"shard-001","component":"tag","data":{"label":"ok"},"actor":"valid:userA"}
{"type":"ZONE_MOVE","entity":"shard-001","zone":"zone-a","actor":"valid:userA"}
EV

# Build snapshot and checkpoint
python3 "$ROOT/runtime/world/apply-event.py" "$BASE_SNAPSHOT" "$TRACE" "$SNAPSHOT" >/dev/null
python3 "$ROOT/runtime/checkpoint/checkpoint.py" zone-a "$BASE_SNAPSHOT" "$TRACE" "$SNAPSHOT" "$CHECKPOINT" >/dev/null

# Bundle into nodeA
NODE_A="$STATE_DIR/nodeA"
NODE_B="$STATE_DIR/nodeB"
rm -rf "$NODE_A" "$NODE_B"
mkdir -p "$NODE_A" "$NODE_B"

manifest=$(python3 "$ROOT/runtime/shards/bundle.py" zone-a "$SNAPSHOT" "$TRACE" "$CHECKPOINT" "$NODE_A")

# Simulate mobility by copying bundle to nodeB
cp -r "$NODE_A/zone-a" "$NODE_B/zone-a"

# Restore on nodeB
set +e
restore_out=$(python3 "$ROOT/runtime/shards/restore.py" "$NODE_B/zone-a" 2>&1)
restore_status=$?
set -e

{
  echo "# Phase 34 — Distributed Persistence + Shard Mobility"
  echo "Date: $(date -Iseconds)"
  echo "Manifest: $manifest"
  echo "Restore Status: $restore_status"
  echo "Restore Output: $restore_out"
  if [ "$restore_status" = "0" ]; then
    echo "PASS: shard mobility verified"
  else
    echo "FAIL: shard mobility" 
  fi
} > "$REPORT"

sed -n '1,200p' "$REPORT"

if [ "$restore_status" != "0" ]; then
  exit 1
fi
