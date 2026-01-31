#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BROKER_HOST="${BROKER:-localhost}"
PORT="${PORT:-1883}"
PIDFILE="$ROOT/pipelines/esp32/mosquitto.pid"
LOGFILE="$ROOT/pipelines/esp32/mosquitto.log"

if command -v mosquitto >/dev/null 2>&1; then
  if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" >/dev/null 2>&1; then
    echo "mosquitto already running (pid $(cat "$PIDFILE"))"
    exit 0
  fi
  mosquitto -p "$PORT" -v > "$LOGFILE" 2>&1 &
  echo $! > "$PIDFILE"
  echo "mosquitto started on $BROKER_HOST:$PORT (pid $(cat "$PIDFILE"))"
else
  echo "mosquitto not installed" >&2
  exit 1
fi
