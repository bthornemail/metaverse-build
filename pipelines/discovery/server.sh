#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PORT="${PORT:-9333}"
PROFILE="${PROFILE:-kernel-v1}"
NODE="${NODE:-host-001}"
BROKER_PORT="${BROKER_PORT:-1883}"
UI_PORT="${UI_PORT:-8080}"
GATE_PORT="${GATE_PORT:-7000}"

# Best-effort local IP for reachability response
HOST_IP="${HOST_IP:-}"
if [ -z "$HOST_IP" ]; then
  if command -v ip >/dev/null 2>&1; then
    HOST_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if ($i=="src") {print $(i+1); exit}}')
  fi
fi
if [ -z "$HOST_IP" ]; then
  HOST_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
fi
HOST_IP=${HOST_IP:-127.0.0.1}

NC_BIN="$(command -v lattice-netcat || true)"
if [ -z "$NC_BIN" ]; then
  NC_BIN="$ROOT/../lattice-netcat/lattice-netcat"
fi
if [ ! -x "$NC_BIN" ]; then
  echo "lattice-netcat not found (expected on PATH or at $ROOT/../lattice-netcat/lattice-netcat)" >&2
  exit 1
fi

RESP=$(cat <<JSON
{"profile":"$PROFILE","node":"$NODE","transports":{"gate":"tcp://$HOST_IP:$GATE_PORT","mqtt":"mqtt://$HOST_IP:$BROKER_PORT","ui":"http://$HOST_IP:$UI_PORT"},"qos":["fast","smooth","slow"]}
JSON
)

# Lattice-netcat discovery server: reply on connect (TCP)
# Each connection gets the current response.
while true; do
  printf "%s" "$RESP" | "$NC_BIN" -l -p "$PORT" >/dev/null 2>&1 || true
  sleep 0.1
  # refresh response in case host IP changes
  HOST_IP="${HOST_IP}"
  if command -v ip >/dev/null 2>&1; then
    HOST_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if ($i=="src") {print $(i+1); exit}}')
  fi
  if [ -z "$HOST_IP" ]; then
    HOST_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
  fi
  HOST_IP=${HOST_IP:-127.0.0.1}
  RESP=$(cat <<JSON
{"profile":"$PROFILE","node":"$NODE","transports":{"gate":"tcp://$HOST_IP:$GATE_PORT","mqtt":"mqtt://$HOST_IP:$BROKER_PORT","ui":"http://$HOST_IP:$UI_PORT"},"qos":["fast","smooth","slow"]}
JSON
)

  if [ "${ONCE:-}" = "1" ]; then
    break
  fi
 done
