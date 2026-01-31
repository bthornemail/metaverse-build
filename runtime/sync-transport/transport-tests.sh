#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STATE_DIR="$ROOT/runtime/sync-transport/state"
BUS_FIFO="$STATE_DIR/bus.fifo"
LOG_DIR="$ROOT/runtime/sync-world/state/logs"
MERGED_LOG="$ROOT/runtime/sync-world/state/merged.jsonl"
REPORT="$ROOT/reports/phase30A-transport.txt"

IR="$ROOT/world-ir/build/room.ir.json"
BASE_SNAPSHOT="$ROOT/runtime/world/snapshots/room.snapshot.json"

mkdir -p "$STATE_DIR" "$LOG_DIR" "$ROOT/reports"
rm -f "$LOG_DIR"/*.jsonl "$MERGED_LOG" "$REPORT"

# Ensure base snapshot exists
bash "$ROOT/runtime/world/load-ir.sh" "$IR" >/dev/null

# Start receiver
rm -f "$BUS_FIFO"
mkfifo "$BUS_FIFO"
"$ROOT/runtime/sync-transport/receive.sh" fifo "$BUS_FIFO" "$LOG_DIR/received.jsonl" &
recv_pid=$!

# Send envelopes from two peers over transport
cat <<'EV' | "$ROOT/runtime/sync-transport/send.sh" fifo "$BUS_FIFO"
{"peer":"peer-A","seq":1,"event":{"type":"ENTITY_CREATE","id":"multi-001","owner":"valid:userA","actor":"valid:userA"}}
{"peer":"peer-A","seq":2,"event":{"type":"COMPONENT_ATTACH","entity":"multi-001","component":"tag","data":{"label":"ok"},"actor":"valid:userA"}}
{"peer":"peer-A","seq":3,"event":{"type":"COMPONENT_UPDATE","entity":"multi-001","component":"tag","patch":{"label":"ok2"},"actor":"valid:userA"}}
{"peer":"peer-B","seq":1,"event":{"type":"COMPONENT_UPDATE","entity":"multi-001","component":"tag","patch":{"label":"nope"},"actor":"valid:userB"}}
EV

# Give receiver time to flush
sleep 0.1
kill "$recv_pid" >/dev/null 2>&1 || true
wait "$recv_pid" 2>/dev/null || true

# Merge logs
bash "$ROOT/runtime/sync-world/merge.sh" "$LOG_DIR" "$MERGED_LOG" >/dev/null

# Apply merged log for two peers
SNAP_A="$STATE_DIR/peerA.snapshot.json"
SNAP_B="$STATE_DIR/peerB.snapshot.json"
HALT_A="$STATE_DIR/peerA.halts.log"
HALT_B="$STATE_DIR/peerB.halts.log"

hash_a=$(bash "$ROOT/runtime/sync-world/apply-merged.sh" "$BASE_SNAPSHOT" "$MERGED_LOG" "$SNAP_A" "$HALT_A")
hash_b=$(bash "$ROOT/runtime/sync-world/apply-merged.sh" "$BASE_SNAPSHOT" "$MERGED_LOG" "$SNAP_B" "$HALT_B")

# Hash before invalid event (apply only peer-A events)
MERGED_VALID="$STATE_DIR/merged.valid.jsonl"
python3 - <<PY
import json
out = open("$MERGED_VALID","w")
for line in open("$MERGED_LOG","r"):
    env = json.loads(line)
    if env.get("peer") == "peer-B":
        continue
    out.write(json.dumps(env, separators=(",", ":")) + "\n")
out.close()
PY

hash_valid=$(bash "$ROOT/runtime/sync-world/apply-merged.sh" "$BASE_SNAPSHOT" "$MERGED_VALID" "$STATE_DIR/valid.snapshot.json" "$STATE_DIR/valid.halts.log")

{
  echo "# Phase 30A — Transport Reality"
  echo "Date: $(date -Iseconds)"
  echo "IR: $IR"
  echo "Base Snapshot: $BASE_SNAPSHOT"
  echo "Transport: fifo"
  echo "Bus FIFO: $BUS_FIFO"
  echo "Received Log: $LOG_DIR/received.jsonl"
  echo "Merged Log: $MERGED_LOG"
  echo "Peer A Snapshot: $SNAP_A"
  echo "Peer B Snapshot: $SNAP_B"
  echo "Hash Peer A: $hash_a"
  echo "Hash Peer B: $hash_b"
  if [ "$hash_a" = "$hash_b" ]; then
    echo "PASS: peers converge"
  else
    echo "FAIL: peer divergence"
  fi
  echo "Valid-Only Hash: $hash_valid"
  echo "HALT A Log: $(cat "$HALT_A" 2>/dev/null || true)"
  echo "HALT B Log: $(cat "$HALT_B" 2>/dev/null || true)"
  if [ "$hash_a" = "$hash_valid" ] && [ "$hash_b" = "$hash_valid" ]; then
    echo "PASS: authority rejection preserves state"
  else
    echo "FAIL: authority rejection changed state"
  fi
} > "$REPORT"

sed -n '1,200p' "$REPORT"

if [ "$hash_a" != "$hash_b" ]; then
  exit 1
fi
if [ "$hash_a" != "$hash_valid" ]; then
  exit 1
fi
