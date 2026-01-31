#!/usr/bin/env bash
set -euo pipefail

TOPIC="${TOPIC:-metaverse/trace}"
BROKER="${BROKER:-localhost}"
PORT="${PORT:-1883}"

if command -v mosquitto_sub >/dev/null 2>&1; then
  mosquitto_sub -h "$BROKER" -p "$PORT" -t "$TOPIC" -v
else
  echo "mosquitto_sub not installed" >&2
  exit 1
fi
