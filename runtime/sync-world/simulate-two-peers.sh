#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STATE_DIR="$ROOT/runtime/sync-world/state"
LOG_DIR="$STATE_DIR/logs"
MERGED_LOG="$STATE_DIR/merged.jsonl"
REPORT="$ROOT/reports/phase29-sync.txt"

IR="$ROOT/world-ir/build/room.ir.json"
BASE_SNAPSHOT="$ROOT/runtime/world/snapshots/room.snapshot.json"

PEER_A="peer-A"
PEER_B="peer-B"

mkdir -p "$STATE_DIR" "$LOG_DIR" "$ROOT/reports"
rm -f "$LOG_DIR"/*.jsonl "$MERGED_LOG"

# Ensure base snapshot exists
bash "$ROOT/runtime/world/load-ir.sh" "$IR" >/dev/null

# Peer A: create + attach + update
cat > "$STATE_DIR/event.a1.json" <<'EV'
{"type":"ENTITY_CREATE","id":"multi-001","owner":"valid:userA","actor":"valid:userA"}
EV
cat > "$STATE_DIR/event.a2.json" <<'EV'
{"type":"COMPONENT_ATTACH","entity":"multi-001","component":"tag","data":{"label":"ok"},"actor":"valid:userA"}
EV
cat > "$STATE_DIR/event.a3.json" <<'EV'
{"type":"COMPONENT_UPDATE","entity":"multi-001","component":"tag","patch":{"label":"ok2"},"actor":"valid:userA"}
EV

bash "$ROOT/runtime/sync-world/append.sh" "$PEER_A" 1 "$STATE_DIR/event.a1.json"
bash "$ROOT/runtime/sync-world/append.sh" "$PEER_A" 2 "$STATE_DIR/event.a2.json"
bash "$ROOT/runtime/sync-world/append.sh" "$PEER_A" 3 "$STATE_DIR/event.a3.json"

# Peer B: invalid update (actor mismatch)
cat > "$STATE_DIR/event.b1.json" <<'EV'
{"type":"COMPONENT_UPDATE","entity":"multi-001","component":"tag","patch":{"label":"nope"},"actor":"valid:userB"}
EV

bash "$ROOT/runtime/sync-world/append.sh" "$PEER_B" 1 "$STATE_DIR/event.b1.json"

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
    if env.get("peer") == "$PEER_B":
        continue
    out.write(json.dumps(env, separators=(",", ":")) + "\n")
out.close()
PY

hash_valid=$(bash "$ROOT/runtime/sync-world/apply-merged.sh" "$BASE_SNAPSHOT" "$MERGED_VALID" "$STATE_DIR/valid.snapshot.json" "$STATE_DIR/valid.halts.log")

{
  echo "# Phase 29 — Multiplayer Sync Scaffolding"
  echo "Date: $(date -Iseconds)"
  echo "IR: $IR"
  echo "Base Snapshot: $BASE_SNAPSHOT"
  echo "Peer Logs: $LOG_DIR"
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
