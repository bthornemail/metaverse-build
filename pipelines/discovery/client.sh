#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-9333}"

NC_BIN="$(command -v lattice-netcat || true)"
if [ -z "$NC_BIN" ]; then
  NC_BIN="$ROOT/../lattice-netcat/lattice-netcat"
fi
if [ ! -x "$NC_BIN" ]; then
  echo "lattice-netcat not found (expected on PATH or at $ROOT/../lattice-netcat/lattice-netcat)" >&2
  exit 1
fi

# Discovery client: connect and read JSON response
TIMEOUT="${DISCOVERY_TIMEOUT:-2}"
if command -v timeout >/dev/null 2>&1; then
  timeout "$TIMEOUT" "$NC_BIN" "$HOST" "$PORT"
else
  "$NC_BIN" "$HOST" "$PORT"
fi
