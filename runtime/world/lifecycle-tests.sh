#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REPORT="$ROOT/reports/phase27-lifecycle.txt"
AUTH_REPORT="$ROOT/reports/phase27B-authority.txt"

IR="$ROOT/world-ir/build/room.ir.json"
SEED_TRACE="$ROOT/runtime/world/trace/room.seed.jsonl"
SNAPSHOT="$ROOT/runtime/world/snapshots/room.snapshot.json"
EVENTS="$ROOT/runtime/world/trace/room.lifecycle.jsonl"
SNAPSHOT_A="$ROOT/runtime/world/snapshots/room.lifecycle.a.json"
SNAPSHOT_B="$ROOT/runtime/world/snapshots/room.lifecycle.b.json"
AUTH_PRE_EVENTS="$ROOT/runtime/world/trace/room.authority.pre.jsonl"
AUTH_FAIL_EVENTS="$ROOT/runtime/world/trace/room.authority.fail.jsonl"
AUTH_PASS_EVENTS="$ROOT/runtime/world/trace/room.authority.pass.jsonl"
AUTH_PRE_SNAP="$ROOT/runtime/world/snapshots/room.authority.pre.json"
AUTH_PASS_SNAP="$ROOT/runtime/world/snapshots/room.authority.pass.json"
AUTH_FAIL_SNAP="$ROOT/runtime/world/snapshots/room.authority.fail.json"

mkdir -p "$ROOT/runtime/world/trace" "$ROOT/runtime/world/snapshots" "$ROOT/reports"

# Ensure base snapshot + seed trace
bash "$ROOT/runtime/world/load-ir.sh" "$IR" >/dev/null

cat > "$EVENTS" <<EV
{"type":"ENTITY_CREATE","id":"test-001","owner":"valid:userA","actor":"valid:userA"}
{"type":"COMPONENT_ATTACH","entity":"test-001","component":"tag","data":{"label":"test"},"actor":"valid:userA"}
{"type":"COMPONENT_UPDATE","entity":"test-001","component":"tag","patch":{"label":"test2"},"actor":"valid:userA"}
{"type":"ZONE_MOVE","entity":"test-001","zone":"room-b","actor":"valid:userA"}
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

# Authority PASS: owner == actor
cat > "$AUTH_PASS_EVENTS" <<EV
{"type":"ENTITY_CREATE","id":"auth-001","owner":"valid:userA","actor":"valid:userA"}
{"type":"COMPONENT_ATTACH","entity":"auth-001","component":"tag","data":{"label":"ok"},"actor":"valid:userA"}
EV

auth_pass_hash=$(python3 "$ROOT/runtime/world/apply-event.py" "$SNAPSHOT" "$AUTH_PASS_EVENTS" "$AUTH_PASS_SNAP")

# Authority FAIL: owner != actor
cat > "$AUTH_PRE_EVENTS" <<EV
{"type":"ENTITY_CREATE","id":"auth-002","owner":"valid:userA","actor":"valid:userA"}
EV

auth_pre_hash=$(python3 "$ROOT/runtime/world/apply-event.py" "$SNAPSHOT" "$AUTH_PRE_EVENTS" "$AUTH_PRE_SNAP")

cat > "$AUTH_FAIL_EVENTS" <<EV
{"type":"COMPONENT_UPDATE","entity":"auth-002","component":"tag","patch":{"label":"nope"},"actor":"valid:userB"}
EV

set +e
halt_msg=$(python3 "$ROOT/runtime/world/apply-event.py" "$AUTH_PRE_SNAP" "$AUTH_FAIL_EVENTS" "$AUTH_FAIL_SNAP" 2>&1 >/dev/null)
halt_status=$?
set -e

auth_pre_hash_after=$(python3 -c 'import hashlib,sys;print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$AUTH_PRE_SNAP")

{
  echo "# Phase 27B — Authority Enforcement"
  echo "Date: $(date -Iseconds)"
  echo "IR: $IR"
  echo "Seed Trace: $SEED_TRACE"
  echo "PASS Events: $AUTH_PASS_EVENTS"
  echo "PASS Snapshot: $AUTH_PASS_SNAP"
  echo "PASS Hash: $auth_pass_hash"
  echo "FAIL Pre Events: $AUTH_PRE_EVENTS"
  echo "FAIL Pre Snapshot: $AUTH_PRE_SNAP"
  echo "FAIL Pre Hash: $auth_pre_hash"
  echo "FAIL Events: $AUTH_FAIL_EVENTS"
  echo "HALT Status: $halt_status"
  echo "HALT Message: $halt_msg"
  echo "FAIL Snapshot Exists: $(test -f "$AUTH_FAIL_SNAP" && echo yes || echo no)"
  echo "FAIL Hash Unchanged: $auth_pre_hash_after"
  if [ "$halt_status" -ne 0 ] && [ "$auth_pre_hash" = "$auth_pre_hash_after" ]; then
    echo "PASS: HALT enforced and hash unchanged"
  else
    echo "FAIL: authority enforcement incomplete"
  fi
} > "$AUTH_REPORT"

sed -n '1,200p' "$AUTH_REPORT"
