#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PORT="${PORT:-7070}"
PLAN_FILE="${PLAN_FILE:-$ROOT/runtime/lattice/plan/device-plan.json}"
PIDFILE="$ROOT/pipelines/discovery/plan-server.pid"

NC_BIN="$(command -v lattice-netcat || true)"
if [ -z "$NC_BIN" ]; then
  NC_BIN="$ROOT/../lattice-netcat/lattice-netcat"
fi
if [ ! -x "$NC_BIN" ]; then
  echo "lattice-netcat not found" >&2
  exit 1
fi

if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" >/dev/null 2>&1; then
  echo "plan server already running (pid $(cat "$PIDFILE"))"
  exit 0
fi

if [ ! -f "$PLAN_FILE" ]; then
  echo "plan file missing: $PLAN_FILE" >&2
  exit 1
fi

(
  while true; do
    printf 'HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n' | \
      cat - "$PLAN_FILE" | \
      "$NC_BIN" -l -p "$PORT" >/dev/null 2>&1
    if [ "${ONCE:-}" = "1" ]; then
      break
    fi
  done
) &

echo $! > "$PIDFILE"

echo "plan server started on port $PORT (pid $(cat "$PIDFILE"))"
