#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STATE_DIR="$ROOT/runtime/checkpoint/state"
REPORT="$ROOT/reports/phase33A-checkpoint.txt"
TRACE_DIR="$ROOT/runtime/world/trace"
SNAP_DIR="$ROOT/runtime/world/snapshots"

IR="$ROOT/world-ir/build/room.ir.json"
BASE_SNAPSHOT="$SNAP_DIR/room.snapshot.json"

mkdir -p "$STATE_DIR" "$TRACE_DIR" "$SNAP_DIR" "$ROOT/reports"

bash "$ROOT/runtime/world/load-ir.sh" "$IR" >/dev/null

TRACE_FULL="$STATE_DIR/zone.trace.jsonl"
TRACE_PART="$STATE_DIR/zone.trace.part.jsonl"
TRACE_FULL_PATH="$STATE_DIR/zone.trace.full.jsonl"
CHECKPOINT="$STATE_DIR/zone.checkpoint.json"
SNAPSHOT_CP="$STATE_DIR/zone.snapshot.json"
SNAPSHOT_RESTORED="$STATE_DIR/zone.restored.json"
SNAPSHOT_EXPECT="$STATE_DIR/zone.expected.json"

cat > "$TRACE_FULL" <<EV
{"type":"ENTITY_CREATE","id":"cp-001","owner":"valid:userA","actor":"valid:userA"}
{"type":"COMPONENT_ATTACH","entity":"cp-001","component":"tag","data":{"label":"ok"},"actor":"valid:userA"}
{"type":"ZONE_MOVE","entity":"cp-001","zone":"zone-a","actor":"valid:userA"}
{"type":"COMPONENT_UPDATE","entity":"cp-001","component":"tag","patch":{"label":"ok2"},"actor":"valid:userA"}
EV

head -n 2 "$TRACE_FULL" > "$TRACE_PART"

# Compute expected snapshot from full trace
python3 "$ROOT/runtime/world/apply-event.py" "$BASE_SNAPSHOT" "$TRACE_FULL" "$SNAPSHOT_EXPECT" >/dev/null

# Create checkpoint from partial trace
python3 "$ROOT/runtime/checkpoint/checkpoint.py" zone-a "$BASE_SNAPSHOT" "$TRACE_PART" "$SNAPSHOT_CP" "$CHECKPOINT" >/dev/null

# Use full trace to simulate append after checkpoint
cat "$TRACE_FULL" > "$TRACE_FULL_PATH"
python3 - <<PY
import json
ck = json.load(open("$CHECKPOINT","r"))
ck["trace"] = "$TRACE_FULL_PATH"
open("$CHECKPOINT","w").write(json.dumps(ck, sort_keys=True, separators=(",", ":")))
PY

# Restore (replay tail)
restored_hash=$(python3 "$ROOT/runtime/checkpoint/restore.py" "$CHECKPOINT" "$SNAPSHOT_RESTORED")

# Expected hash
expected_hash=$(python3 - <<PY
import hashlib
print(hashlib.sha256(open("$SNAPSHOT_EXPECT","rb").read()).hexdigest())
PY
)

# Corruption check
CORRUPT="$STATE_DIR/zone.snapshot.corrupt.json"
cp "$SNAPSHOT_CP" "$CORRUPT"
printf '\n' >> "$CORRUPT"
set +e
python3 "$ROOT/runtime/checkpoint/restore.py" <(cat "$CHECKPOINT" | sed "s|$SNAPSHOT_CP|$CORRUPT|") "$STATE_DIR/zone.restore.fail.json" 2>"$STATE_DIR/corrupt.stderr"
corrupt_status=$?
set -e

{
  echo "# Phase 33A — Checkpoint Kernel"
  echo "Date: $(date -Iseconds)"
  echo "IR: $IR"
  echo "Base Snapshot: $BASE_SNAPSHOT"
  echo "Checkpoint: $CHECKPOINT"
  echo "Expected Hash: $expected_hash"
  echo "Restored Hash: $restored_hash"
  if [ "$expected_hash" = "$restored_hash" ]; then
    echo "PASS: restore equals expected"
  else
    echo "FAIL: restore mismatch"
  fi
  echo "Corrupt Status: $corrupt_status"
  echo "Corrupt Stderr: $(cat "$STATE_DIR/corrupt.stderr" 2>/dev/null || true)"
  if [ "$corrupt_status" = "3" ]; then
    echo "PASS: corruption detected"
  else
    echo "FAIL: corruption not detected"
  fi
} > "$REPORT"

sed -n '1,200p' "$REPORT"

if [ "$expected_hash" != "$restored_hash" ]; then
  exit 1
fi
if [ "$corrupt_status" != "3" ]; then
  exit 1
fi
