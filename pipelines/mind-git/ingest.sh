#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT_ROOT="$ROOT/projections/mind-git"
STORE="$OUT_ROOT/store"
INDEX="$OUT_ROOT/index"

mkdir -p "$STORE" "$INDEX"

now=$(date -Iseconds)

inputs=(
  "$ROOT/runtime/lattice/trace/discovery.log"
  "$ROOT/runtime/lattice/trace/routing.log"
  "$ROOT/runtime/lattice/graph/peergraph.json"
  "$ROOT/runtime/lattice/graph/basis.json"
  "$ROOT/runtime/lattice/plan/connection-plan.json"
)

for f in "$ROOT"/reports/*.txt; do
  [ -f "$f" ] && inputs+=("$f") || true
done

for f in "${inputs[@]}"; do
  [ -f "$f" ] || continue
  hash=$(sha256sum "$f" | awk '{print $1}')
  size=$(wc -c < "$f" | tr -d ' ')
  obj="$STORE/$hash.json"
  if [ ! -f "$obj" ]; then
    python3 - <<PY
import json, sys
obj = {
  "hash": "$hash",
  "path": "$f",
  "size": $size,
  "time": "$now"
}
with open("$obj","w") as fh:
  json.dump(obj, fh, separators=(",",":"))
PY
  fi
  printf '{"t":"%s","path":"%s","hash":"%s","size":%s}\n' "$now" "$f" "$hash" "$size" >> "$INDEX/ingest.jsonl"
done

python3 - <<PY
import json, os, hashlib
root = "$ROOT"
latest = {}
keys = {
  "peergraph": "runtime/lattice/graph/peergraph.json",
  "basis": "runtime/lattice/graph/basis.json",
  "plan": "runtime/lattice/plan/connection-plan.json",
  "discovery_log": "runtime/lattice/trace/discovery.log",
  "routing_log": "runtime/lattice/trace/routing.log",
}
for k, rel in keys.items():
  path = os.path.join(root, rel)
  if os.path.exists(path):
    with open(path, "rb") as fh:
      h = hashlib.sha256(fh.read()).hexdigest()
    latest[k] = {"path": path, "hash": h}
out = os.path.join("$INDEX", "latest.json")
with open(out, "w") as fh:
  json.dump(latest, fh, indent=2)
PY

echo "Ingested $(printf "%s\n" "${inputs[@]}" | wc -l | tr -d ' ') files."
