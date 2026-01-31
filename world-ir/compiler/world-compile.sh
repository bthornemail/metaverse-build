#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT_DIR="$ROOT/world-ir/build"
IN_FILE="${1:-}"

if [ -z "$IN_FILE" ]; then
  echo "usage: world-compile.sh <world.json>" >&2
  exit 2
fi

if [ ! -f "$IN_FILE" ]; then
  echo "input file not found: $IN_FILE" >&2
  exit 2
fi

mkdir -p "$OUT_DIR"

python3 - <<PY
import json, sys, os

in_path = os.path.abspath("$IN_FILE")
with open(in_path, "r") as fh:
    data = json.load(fh)

# Minimal validation (schema-level checks without external deps)
if not isinstance(data, dict):
    raise SystemExit("world must be an object")
if "world" not in data or not isinstance(data["world"], str):
    raise SystemExit("world must have string 'world' field")

entities = data.get("entities", [])
if entities is not None:
    if not isinstance(entities, list):
        raise SystemExit("entities must be an array")
    for e in entities:
        if not isinstance(e, dict):
            raise SystemExit("entity must be an object")
        if "id" not in e or not isinstance(e["id"], str):
            raise SystemExit("entity.id must be string")
        comps = e.get("components", [])
        if not isinstance(comps, list):
            raise SystemExit("entity.components must be array")
        for c in comps:
            if not isinstance(c, dict):
                raise SystemExit("component must be object")
            if "type" not in c or not isinstance(c["type"], str):
                raise SystemExit("component.type must be string")

# Normalize
norm = json.dumps(data, sort_keys=True, separators=(",", ":"))
name = data["world"]
out_path = os.path.join("$OUT_DIR", f"{name}.ir.json")
with open(out_path, "w") as fh:
    fh.write(norm)

print(out_path)
PY
