#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
IN_IR="${1:-}"
VALIDATE_IR="$ROOT/world-ir/validate-ir.py"

if [ -z "$IN_IR" ]; then
  echo "usage: load-ir.sh <world.ir.json>" >&2
  exit 2
fi

if [ ! -f "$IN_IR" ]; then
  echo "input not found: $IN_IR" >&2
  exit 2
fi

python3 "$VALIDATE_IR" "$IN_IR" >/dev/null || {
  echo "schema validation failed: $IN_IR" >&2
  exit 2
}

world_name=$(python3 - <<PY
import json
with open("$IN_IR","r") as fh:
    data=json.load(fh)
print(data.get("world","unknown"))
PY
)

SNAP_DIR="$ROOT/runtime/world/snapshots"
TRACE_DIR="$ROOT/runtime/world/trace"
REPORT="$ROOT/reports/phase26-world-load.txt"
CONFORMANCE="$TRACE_DIR/${world_name}.runtime.conformance.json"
RUNTIME_TRACE="$TRACE_DIR/${world_name}.runtime.trace.ndjson"
RUNTIME_SNAPSHOT="$SNAP_DIR/${world_name}.runtime.snapshot.json"
REPLAY_SNAPSHOT="$SNAP_DIR/${world_name}.runtime.replay.snapshot.json"

mkdir -p "$SNAP_DIR" "$TRACE_DIR" "$ROOT/reports"

SNAPSHOT="$SNAP_DIR/${world_name}.snapshot.json"
TRACE="$TRACE_DIR/${world_name}.seed.jsonl"

hash=$(python3 "$ROOT/runtime/world/materialize.py" "$IN_IR" "$SNAPSHOT" "$TRACE")
replay_hash=$(python3 "$ROOT/runtime/world/replay.py" "$TRACE" "$REPLAY_SNAPSHOT")
if [[ "$hash" != "$replay_hash" ]]; then
  echo "replay mismatch: materialize=$hash replay=$replay_hash" >&2
  exit 2
fi

cp "$TRACE" "$RUNTIME_TRACE"
cp "$SNAPSHOT" "$RUNTIME_SNAPSHOT"

world_ir_digest="$(python3 - <<PY
import json,hashlib
with open("$IN_IR","r") as fh:
    obj=json.load(fh)
canon=json.dumps(obj,sort_keys=True,separators=(",",":"))+"\\n"
print("sha256:"+hashlib.sha256(canon.encode("utf-8")).hexdigest())
PY
)"
trace_digest="sha256:$(sha256sum "$RUNTIME_TRACE" | awk '{print $1}')"
snapshot_digest="sha256:$(sha256sum "$RUNTIME_SNAPSHOT" | awk '{print $1}')"
replay_snapshot_digest="sha256:$(sha256sum "$REPLAY_SNAPSHOT" | awk '{print $1}')"

python3 - <<PY > "$CONFORMANCE"
import json
obj={
  "v":"metaverse-build.runtime.conformance.world_ir.v0",
  "world":"$world_name",
  "world_ir_digest":"$world_ir_digest",
  "runtime_trace_digest":"$trace_digest",
  "runtime_snapshot_digest":"$snapshot_digest",
  "replay_snapshot_digest":"$replay_snapshot_digest",
  "materialize_hash":"sha256:$hash",
  "replay_hash":"sha256:$replay_hash",
  "deterministic":"1"
}
print(json.dumps(obj,sort_keys=True,separators=(",",":")))
PY

{
  echo "# Phase 26 — World IR Load"
  echo "World: $world_name"
  echo "IR: $IN_IR"
  echo "Snapshot: $SNAPSHOT"
  echo "Trace: $TRACE"
  echo "Runtime Snapshot: $RUNTIME_SNAPSHOT"
  echo "Runtime Trace: $RUNTIME_TRACE"
  echo "Conformance: $CONFORMANCE"
  echo "Snapshot SHA256: $hash"
  echo "Replay SHA256: $replay_hash"
} > "$REPORT"

sed -n '1,200p' "$REPORT"
