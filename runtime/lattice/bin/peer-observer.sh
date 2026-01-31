#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
FIFO="$ROOT/runtime/lattice/state/peers/beacons.fifo"
OBS="$ROOT/runtime/lattice/state/peers/observed.jsonl"
TRACE="$ROOT/runtime/lattice/state/traces/discovery.log"

[ -p "$FIFO" ] || mkfifo "$FIFO"
: > "$OBS"

while IFS= read -r line; do
  [ -n "$line" ] || continue
  ts=$(date +%s)
  echo "$line" >> "$OBS"
  printf '{"t":%s,"type":"discovery","raw":%s}\n' "$ts" "${line}" >> "$TRACE"
done < "$FIFO"
