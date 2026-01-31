#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FIFO="$ROOT/runtime/lattice/peers/observe/beacons.fifo"
OBS="$ROOT/runtime/lattice/peers/observe/observed.jsonl"
TRACE="$ROOT/runtime/lattice/trace/discovery.log"

[ -d "$(dirname "$OBS")" ] || mkdir -p "$(dirname "$OBS")"
[ -d "$(dirname "$TRACE")" ] || mkdir -p "$(dirname "$TRACE")"
[ -p "$FIFO" ] || mkfifo "$FIFO"

while IFS= read -r line; do
  [ -n "$line" ] || continue
  ts=$(date +%s)
  echo "$line" >> "$OBS"
  printf '{"t":%s,"type":"beacon_seen","raw":%s}\n' "$ts" "$line" >> "$TRACE"
done < "$FIFO"
