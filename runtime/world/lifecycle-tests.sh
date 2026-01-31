#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REPORT="$ROOT/reports/phase27-lifecycle.txt"

IR="$ROOT/world-ir/build/room.ir.json"
SEED_TRACE="$ROOT/runtime/world/trace/room.seed.jsonl"
SNAPSHOT="$ROOT/runtime/world/snapshots/room.snapshot.json"
EVENTS="$ROOT/runtime/world/trace/room.lifecycle.jsonl"
SNAPSHOT_A="$ROOT/runtime/world/snapshots/room.lifecycle.a.json"
SNAPSHOT_B="$ROOT/runtime/world/snapshots/room.lifecycle.b.json"

mkdir -p "$ROOT/runtime/world/trace" "$ROOT/runtime/world/snapshots" "$ROOT/reports"

# Ensure base snapshot + seed trace
bash "$ROOT/runtime/world/load-ir.sh" "$IR" >/dev/null

cat > "$EVENTS" <<EV
{"type":"COMPONENT_UPDATE","entity":"cube-001","component":"transform","patch":{"position":[1,2,3]}}
{"type":"ZONE_MOVE","entity":"cube-001","zone":"room-b"}
{"type":"COMPONENT_ATTACH","entity":"cube-001","component":"tag","data":{"label":"test"}}
EV

hash_a=$(python3 "$ROOT/runtime/world/apply-event.py" "$SNAPSHOT" "$EVENTS" "$SNAPSHOT_A")
# Replay by applying same events again to original snapshot
hash_b=$(python3 "$ROOT/runtime/world/apply-event.py" "$SNAPSHOT" "$EVENTS" "$SNAPSHOT_B")

{
  echo "# Phase 27 — Lifecycle Determinism"
  echo "Date: $(date -Iseconds)"
  echo "IR: $IR"
  echo "Seed Trace: $SEED_TRACE"
  echo "Events: $EVENTS"
  echo "Snapshot A: $SNAPSHOT_A"
  echo "Snapshot B: $SNAPSHOT_B"
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
