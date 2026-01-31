#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
ENV_FILE="${BUS_ENV:-$ROOT/pipelines/posix-bus/bus.env}"
STATE_DIR="$ROOT/pipelines/posix-bus/tcp/state"
PIDFILE="$STATE_DIR/listen.pid"
PORTFILE="$STATE_DIR/listen.port"
OUTFILE="$STATE_DIR/trace.out"

mkdir -p "$STATE_DIR"

if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  . "$ENV_FILE"
fi

BUS_TCP="${BUS_TCP:-tcp://127.0.0.1:7000}"

NC_BIN="$(command -v lattice-netcat || true)"
if [ -z "$NC_BIN" ]; then
  NC_BIN="$ROOT/../lattice-netcat/lattice-netcat"
fi
if [ ! -x "$NC_BIN" ]; then
  echo "lattice-netcat not found" >&2
  exit 1
fi

host=$(printf "%s" "$BUS_TCP" | sed -n 's|tcp://\([^:/]*\).*|\1|p')
port=$(printf "%s" "$BUS_TCP" | sed -n 's|tcp://[^:/]*:\([0-9][0-9]*\).*|\1|p')
: "${port:?missing tcp port}"

# If already running, restart when port changes
if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" >/dev/null 2>&1; then
  if [ -f "$PORTFILE" ] && [ "$(cat "$PORTFILE")" != "$port" ]; then
    kill "$(cat "$PIDFILE")" >/dev/null 2>&1 || true
    rm -f "$PIDFILE"
  else
    echo "tcp listener already running (pid $(cat "$PIDFILE"))"
    exit 0
  fi
fi

# Start listener
# Each connection writes to trace.out; this is projection-only
(
  while true; do
    "$NC_BIN" -l -p "$port" | tee -a "$OUTFILE" >/dev/null
    if [ "${ONCE:-}" = "1" ]; then
      break
    fi
  done
) &

echo $! > "$PIDFILE"
echo "$port" > "$PORTFILE"

echo "tcp listener started on $host:$port (pid $(cat "$PIDFILE"))"
