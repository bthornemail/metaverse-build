#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-9334}"
NODE="${NODE:-esp32-001}"
PROFILE="${PROFILE:-kernel-v1}"
ADDR="${ADDR:-192.168.1.44}"
MQTT_PORT="${MQTT_PORT:-1883}"
GATE_PORT="${GATE_PORT:-7000}"
UI_PORT="${UI_PORT:-8080}"

NC_BIN="$(command -v lattice-netcat || true)"
if [ -z "$NC_BIN" ]; then
  NC_BIN="$ROOT/../lattice-netcat/lattice-netcat"
fi
if [ ! -x "$NC_BIN" ]; then
  echo "lattice-netcat not found" >&2
  exit 1
fi

MSG=$(cat <<JSON
{"type":"beacon","node":"$NODE","profile":"$PROFILE","addr":"$ADDR","ports":{"mqtt":$MQTT_PORT,"gate":$GATE_PORT,"ui":$UI_PORT},"caps":["mqtt","ui"],"epoch":$(date +%s)}
JSON
)

printf "%s\n" "$MSG" | "$NC_BIN" -u --udp-wait 0 "$HOST" "$PORT"
