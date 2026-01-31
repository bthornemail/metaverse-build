#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
FIFO="$ROOT/runtime/lattice/peers/observe/beacons.fifo"
OBS="$ROOT/runtime/lattice/peers/observe/observed.jsonl"
TRACE="$ROOT/runtime/lattice/trace/discovery.log"
BEACON_IN="${BEACON_IN:-$FIFO}"

[ -d "$(dirname "$OBS")" ] || mkdir -p "$(dirname "$OBS")"
[ -d "$(dirname "$TRACE")" ] || mkdir -p "$(dirname "$TRACE")"

if [ "$BEACON_IN" = "-" ]; then
  INPUT="/dev/stdin"
  READER="cat"
elif [ -p "$BEACON_IN" ]; then
  INPUT="$BEACON_IN"
  READER="cat"
else
  INPUT="$BEACON_IN"
  READER="tail -n +1 -F"
fi

$READER "$INPUT" | while IFS= read -r line; do
  [ -n "$line" ] || continue
  ts=$(date +%s)
  echo "$line" >> "$OBS"
  printf '{"t":%s,"type":"beacon_seen","raw":%s}\n' "$ts" "$line" >> "$TRACE"
done
