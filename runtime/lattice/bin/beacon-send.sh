#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-9334}"
DISCOVERY_MODE="${DISCOVERY_MODE:-udp}"
CLIENT_TIMEOUT="${CLIENT_TIMEOUT:-1}"
DISCOVERY_TCP_IMPL="${DISCOVERY_TCP_IMPL:-socat}"
NODE="${NODE:-esp32-001}"
PROFILE="${PROFILE:-kernel-v1}"
ADDR="${ADDR:-}"
BUS_PORT="${BUS_PORT:-7000}"
UI_PORT="${UI_PORT:-8080}"
RTT_MS="${RTT_MS:-}"

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

RTT_FIELD=""
if [ -n "$RTT_MS" ]; then
  RTT_FIELD=",\"rtt_ms\":$RTT_MS"
fi

MSG=$(cat <<JSON
{"type":"beacon","node":"$NODE","profile":"$PROFILE","addr":"$ADDR","ports":{"bus":$BUS_PORT,"ui":$UI_PORT},"caps":["bus","ui"]$RTT_FIELD,"epoch":$(date +%s)}
JSON
)

if [ "$DISCOVERY_MODE" = "tcp" ]; then
  if [ "$DISCOVERY_TCP_IMPL" = "devtcp" ]; then
    if command -v timeout >/dev/null 2>&1; then
      printf "%s\n" "$MSG" | timeout "$CLIENT_TIMEOUT" bash -c "cat > /dev/tcp/$HOST/$PORT" >/dev/null 2>&1 || true
    else
      printf "%s\n" "$MSG" | bash -c "cat > /dev/tcp/$HOST/$PORT" >/dev/null 2>&1 || true
    fi
  elif [ "$DISCOVERY_TCP_IMPL" = "socat" ] && command -v socat >/dev/null 2>&1; then
    printf "%s\n" "$MSG" | socat - "TCP:${HOST}:${PORT}" >/dev/null 2>&1 || true
  else
    if command -v timeout >/dev/null 2>&1; then
      printf "%s\n" "$MSG" | timeout "$CLIENT_TIMEOUT" "$NC_BIN" "$HOST" "$PORT" >/dev/null 2>&1 || true
    else
      printf "%s\n" "$MSG" | "$NC_BIN" "$HOST" "$PORT" >/dev/null 2>&1 || true
    fi
  fi
else
  printf "%s\n" "$MSG" | "$NC_BIN" -u --udp-wait 0 "$HOST" "$PORT"
fi
