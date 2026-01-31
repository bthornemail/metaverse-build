#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
FIFO="$ROOT/runtime/lattice/peers/observe/beacons.fifo"
PORT="${PORT:-9334}"

NC_BIN="$(command -v lattice-netcat || true)"
if [ -z "$NC_BIN" ]; then
  NC_BIN="$ROOT/../lattice-netcat/lattice-netcat"
fi
if [ ! -x "$NC_BIN" ]; then
  echo "lattice-netcat not found" >&2
  exit 1
fi

[ -p "$FIFO" ] || mkfifo "$FIFO"

# UDP beacon listener writes to FIFO
"$NC_BIN" -u -l -p "$PORT" > "$FIFO"
