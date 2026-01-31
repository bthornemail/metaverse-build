#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-9334}"
NODE="${NODE:-esp32-001}"
PROFILE="${PROFILE:-kernel-v1}"
ADDR="${ADDR:-}"
BUS_PORT="${BUS_PORT:-7000}"
UI_PORT="${UI_PORT:-8080}"

if [ -z "$ADDR" ]; then
  ADDR=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if ($i=="src") {print $(i+1); exit}}')
  ADDR=${ADDR:-127.0.0.1}
fi

NC_BIN="$(command -v lattice-netcat || true)"
if [ -z "$NC_BIN" ]; then
  NC_BIN="$ROOT/../lattice-netcat/lattice-netcat"
fi
if [ ! -x "$NC_BIN" ]; then
  echo "lattice-netcat not found" >&2
  exit 1
fi

MSG=$(cat <<JSON
{"type":"beacon","node":"$NODE","profile":"$PROFILE","addr":"$ADDR","ports":{"bus":$BUS_PORT,"ui":$UI_PORT},"caps":["bus","ui"],"epoch":$(date +%s)}
JSON
)

printf "%s\n" "$MSG" | "$NC_BIN" -u --udp-wait 0 "$HOST" "$PORT"
