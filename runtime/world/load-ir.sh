#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
IN_IR="${1:-}"

if [ -z "$IN_IR" ]; then
  echo "usage: load-ir.sh <world.ir.json>" >&2
  exit 2
fi

if [ ! -f "$IN_IR" ]; then
  echo "input not found: $IN_IR" >&2
  exit 2
fi

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

mkdir -p "$SNAP_DIR" "$TRACE_DIR" "$ROOT/reports"

SNAPSHOT="$SNAP_DIR/${world_name}.snapshot.json"
TRACE="$TRACE_DIR/${world_name}.seed.jsonl"

hash=$(python3 "$ROOT/runtime/world/materialize.py" "$IN_IR" "$SNAPSHOT" "$TRACE")

{
  echo "# Phase 26 — World IR Load"
  echo "Date: $(date -Iseconds)"
  echo "World: $world_name"
  echo "IR: $IN_IR"
  echo "Snapshot: $SNAPSHOT"
  echo "Trace: $TRACE"
  echo "Snapshot SHA256: $hash"
} > "$REPORT"

sed -n '1,200p' "$REPORT"
