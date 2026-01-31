#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
OBS="$ROOT/runtime/lattice/peers/observe/observed.jsonl"
PLAN="$ROOT/runtime/lattice/plan/connection-plan.json"
HASH_FILE="$ROOT/runtime/lattice/plan/connection-plan.sha"
TRACE="$ROOT/runtime/lattice/trace/routing.log"

# Compile graph/basis/plan
bash "$ROOT/runtime/lattice/compiler/graph-basis-compiler.sh"
bash "$ROOT/runtime/lattice/compiler/plan-projector.sh"

# Detect plan change
new_hash=$(sha256sum "$PLAN" | awk '{print $1}')
old_hash=""
[ -f "$HASH_FILE" ] && old_hash=$(cat "$HASH_FILE")

if [ "$new_hash" != "$old_hash" ]; then
  echo "$new_hash" > "$HASH_FILE"
  ts=$(date +%s)
  printf '{"t":%s,"type":"rebind","plan":"%s"}\n' "$ts" "$PLAN" >> "$TRACE"
  bash "$ROOT/runtime/lattice/reconcile/rebind.sh"
fi
