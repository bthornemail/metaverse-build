#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STATE_DIR="$ROOT/runtime/time/state"
REPORT="$ROOT/reports/phase36-merge.txt"

IR="$ROOT/world-ir/build/room.ir.json"
BASE_SNAPSHOT="$ROOT/runtime/world/snapshots/room.snapshot.json"

mkdir -p "$STATE_DIR" "$ROOT/reports"

bash "$ROOT/runtime/world/load-ir.sh" "$IR" >/dev/null

TRACE_A="$STATE_DIR/merge.trace.a.jsonl"
TRACE_B="$STATE_DIR/merge.trace.b.jsonl"

cat > "$TRACE_A" <<EV
{"type":"ENTITY_CREATE","id":"merge-001","owner":"valid:userA","actor":"valid:userA"}
EV

cat > "$TRACE_B" <<EV
{"type":"ENTITY_CREATE","id":"merge-001","owner":"valid:userA","actor":"valid:userA"}
{"type":"COMPONENT_ATTACH","entity":"merge-001","component":"tag","data":{"label":"x"},"actor":"valid:userA"}
EV

CK_A="$STATE_DIR/ck.a.json"
CK_B="$STATE_DIR/ck.b.json"
SNAP_A="$STATE_DIR/snap.a.json"
SNAP_B="$STATE_DIR/snap.b.json"

python3 "$ROOT/runtime/checkpoint/checkpoint.py" zone-a "$BASE_SNAPSHOT" "$TRACE_A" "$SNAP_A" "$CK_A" >/dev/null
python3 "$ROOT/runtime/checkpoint/checkpoint.py" zone-a "$BASE_SNAPSHOT" "$TRACE_A" "$SNAP_A" "$CK_B" >/dev/null

TL_A="$STATE_DIR/timeline.a.json"
TL_B="$STATE_DIR/timeline.b.json"

cat > "$TL_A" <<JSON
{"world":"room","timeline":"A","nodes":{"ck-1":{"checkpoint":"$CK_A","parent":null}}}
JSON

cat > "$TL_B" <<JSON
{"world":"room","timeline":"B","nodes":{"ck-1":{"checkpoint":"$CK_B","parent":null}}}
JSON

# OK merge (identical checkpoints)
set +e
ok_out=$(python3 "$ROOT/runtime/time/merge-check.py" "$TL_A" "$TL_B" "$CK_A" "$CK_B" 2>&1)
ok_status=$?
set -e

# DENY merge (different snapshots)
python3 "$ROOT/runtime/checkpoint/checkpoint.py" zone-a "$BASE_SNAPSHOT" "$TRACE_B" "$SNAP_B" "$CK_B" >/dev/null
set +e
deny_out=$(python3 "$ROOT/runtime/time/merge-check.py" "$TL_A" "$TL_B" "$CK_A" "$CK_B" 2>&1)
deny_status=$?
set -e

{
  echo "# Phase 36 — Timeline Merge Semantics"
  echo "Date: $(date -Iseconds)"
  echo "OK Status: $ok_status"
  echo "OK Output: $ok_out"
  echo "DENY Status: $deny_status"
  echo "DENY Output: $deny_out"
  if [ "$ok_status" = "0" ] && [ "$deny_status" = "3" ]; then
    echo "PASS: merge gate enforced"
  else
    echo "FAIL: merge gate enforced"
  fi
} > "$REPORT"

sed -n '1,200p' "$REPORT"

if [ "$ok_status" != "0" ] || [ "$deny_status" != "3" ]; then
  exit 1
fi
