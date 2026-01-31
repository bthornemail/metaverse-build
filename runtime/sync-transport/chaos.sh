#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STATE_DIR="$ROOT/runtime/sync-transport/state"
LOG_DIR="$ROOT/runtime/sync-world/state/logs"
MERGED_LOG="$ROOT/runtime/sync-world/state/merged.jsonl"
REPORT="$ROOT/reports/phase30A1-chaos.txt"

IR="$ROOT/world-ir/build/room.ir.json"
BASE_SNAPSHOT="$ROOT/runtime/world/snapshots/room.snapshot.json"

mkdir -p "$STATE_DIR" "$LOG_DIR" "$ROOT/reports"
rm -f "$LOG_DIR"/*.jsonl "$MERGED_LOG" "$REPORT"

# Ensure base snapshot exists
bash "$ROOT/runtime/world/load-ir.sh" "$IR" >/dev/null

# Base envelopes
cat > "$STATE_DIR/base.jsonl" <<'EV'
{"peer":"peer-A","seq":1,"event":{"type":"ENTITY_CREATE","id":"multi-001","owner":"valid:userA","actor":"valid:userA"}}
{"peer":"peer-A","seq":2,"event":{"type":"COMPONENT_ATTACH","entity":"multi-001","component":"tag","data":{"label":"ok"},"actor":"valid:userA"}}
{"peer":"peer-A","seq":3,"event":{"type":"COMPONENT_UPDATE","entity":"multi-001","component":"tag","patch":{"label":"ok2"},"actor":"valid:userA"}}
{"peer":"peer-B","seq":1,"event":{"type":"COMPONENT_UPDATE","entity":"multi-001","component":"tag","patch":{"label":"nope"},"actor":"valid:userB"}}
EV

# Chaos: drop seq 2, duplicate invalid, reorder deterministically
STATE_DIR_PATH="$STATE_DIR" python3 - <<'PY'
import json
import random
import os
random.seed(29)

state_dir = os.environ.get("STATE_DIR_PATH", "")
base_path = os.path.join(state_dir, "base.jsonl")
chaos_path = os.path.join(state_dir, "chaos.jsonl")
valid_path = os.path.join(state_dir, "valid.jsonl")

items = []
valid = []

with open(base_path, 'r') as fh:
    for line in fh:
        line = line.strip()
        if not line:
            continue
        env = json.loads(line)
        if env.get('peer') == 'peer-A' and env.get('seq') == 2:
            # drop this event to simulate loss
            continue
        items.append(env)
        if env.get('peer') == 'peer-A':
            valid.append(env)

# duplicate invalid event
for env in list(items):
    if env.get('peer') == 'peer-B':
        items.append(env)

random.shuffle(items)

with open(chaos_path, 'w') as out:
    for env in items:
        out.write(json.dumps(env, separators=(",", ":")) + "\n")

with open(valid_path, 'w') as out:
    for env in valid:
        out.write(json.dumps(env, separators=(",", ":")) + "\n")
PY

# Simulate transport by copying chaos log into received log
cp "$STATE_DIR/chaos.jsonl" "$LOG_DIR/received.jsonl"

# Merge logs (deterministic order by peer, seq)
bash "$ROOT/runtime/sync-world/merge.sh" "$LOG_DIR" "$MERGED_LOG" >/dev/null

# Apply merged log for two peers
SNAP_A="$STATE_DIR/peerA.snapshot.json"
SNAP_B="$STATE_DIR/peerB.snapshot.json"
HALT_A="$STATE_DIR/peerA.halts.log"
HALT_B="$STATE_DIR/peerB.halts.log"

hash_a=$(bash "$ROOT/runtime/sync-world/apply-merged.sh" "$BASE_SNAPSHOT" "$MERGED_LOG" "$SNAP_A" "$HALT_A")
hash_b=$(bash "$ROOT/runtime/sync-world/apply-merged.sh" "$BASE_SNAPSHOT" "$MERGED_LOG" "$SNAP_B" "$HALT_B")

# Apply valid subset (peer-A only, with dropped seq2)
MERGED_VALID="$STATE_DIR/merged.valid.jsonl"
cp "$STATE_DIR/valid.jsonl" "$MERGED_VALID"

hash_valid=$(bash "$ROOT/runtime/sync-world/apply-merged.sh" "$BASE_SNAPSHOT" "$MERGED_VALID" "$STATE_DIR/valid.snapshot.json" "$STATE_DIR/valid.halts.log")

{
  echo "# Phase 30A.1 — Transport Freeze Audit"
  echo "Date: $(date -Iseconds)"
  echo "IR: $IR"
  echo "Base Snapshot: $BASE_SNAPSHOT"
  echo "Chaos Log: $STATE_DIR/chaos.jsonl"
  echo "Merged Log: $MERGED_LOG"
  echo "Hash Peer A: $hash_a"
  echo "Hash Peer B: $hash_b"
  echo "Hash Valid Subset: $hash_valid"
  echo "HALT A Log: $(cat "$HALT_A" 2>/dev/null || true)"
  echo "HALT B Log: $(cat "$HALT_B" 2>/dev/null || true)"
  if [ "$hash_a" = "$hash_b" ]; then
    echo "PASS: deterministic under chaos"
  else
    echo "FAIL: deterministic under chaos"
  fi
  if [ "$hash_a" = "$hash_valid" ]; then
    echo "PASS: authority preserved"
  else
    echo "FAIL: authority preserved"
  fi
  if [ "$hash_a" = "$hash_b" ]; then
    echo "PASS: final hash identical"
  else
    echo "FAIL: final hash identical"
  fi
} > "$REPORT"

sed -n '1,200p' "$REPORT"

if [ "$hash_a" != "$hash_b" ]; then
  exit 1
fi
if [ "$hash_a" != "$hash_valid" ]; then
  exit 1
fi
