#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
FIFO="$ROOT/runtime/lattice/peers/observe/beacons.fifo"
PORT="${PORT:-9334}"
DISCOVERY_MODE="${DISCOVERY_MODE:-udp}"
KEEP_OPEN="${KEEP_OPEN:-1}"
BEACON_OUT="${BEACON_OUT:-}"
DISCOVERY_TCP_IMPL="${DISCOVERY_TCP_IMPL:-socat}"

NC_BIN="$(command -v lattice-netcat || true)"
if [ -z "$NC_BIN" ]; then
  NC_BIN="$ROOT/../lattice-netcat/lattice-netcat"
fi
if [ ! -x "$NC_BIN" ]; then
  echo "lattice-netcat not found" >&2
  exit 1
fi

OUT="${BEACON_OUT:-$FIFO}"
if [ "$OUT" != "-" ] && [ ! -p "$OUT" ]; then
  : > "$OUT"
fi

if [ "$DISCOVERY_MODE" = "tcp" ]; then
  if [ "$DISCOVERY_TCP_IMPL" = "socat" ] && command -v socat >/dev/null 2>&1; then
    if [ "$KEEP_OPEN" = "1" ]; then
      if [ "$OUT" = "-" ]; then
        exec socat -u TCP4-LISTEN:"$PORT",reuseaddr,fork STDOUT
      else
        exec socat -u TCP4-LISTEN:"$PORT",reuseaddr,fork FILE:"$OUT",append
      fi
    else
      if [ "$OUT" = "-" ]; then
        exec socat -u TCP4-LISTEN:"$PORT",reuseaddr STDOUT
      else
        exec socat -u TCP4-LISTEN:"$PORT",reuseaddr FILE:"$OUT",append
      fi
    fi
  else
    if [ "$KEEP_OPEN" = "1" ]; then
      if [ "$OUT" = "-" ]; then
        exec "$NC_BIN" -l -k -p "$PORT"
      else
        exec "$NC_BIN" -l -k -p "$PORT" > "$OUT"
      fi
    else
      if [ "$OUT" = "-" ]; then
        exec "$NC_BIN" -l -p "$PORT"
      else
        exec "$NC_BIN" -l -p "$PORT" > "$OUT"
      fi
    fi
  fi
else
  # UDP beacon listener writes to FIFO
  if [ "$OUT" = "-" ]; then
    exec "$NC_BIN" -u -l -p "$PORT"
  else
    exec "$NC_BIN" -u -l -p "$PORT" > "$OUT"
  fi
fi
