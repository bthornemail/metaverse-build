#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TOPIC="${TOPIC:-metaverse/trace}"
BROKER="${BROKER:-localhost}"
PORT="${PORT:-1883}"
FIFO="$ROOT/pipelines/mqtt/mqtt.mock.fifo"

if command -v mosquitto_sub >/dev/null 2>&1; then
  mosquitto_sub -h "$BROKER" -p "$PORT" -t "$TOPIC" -v
else
  [ -p "$FIFO" ] || mkfifo "$FIFO"
  cat "$FIFO"
fi
