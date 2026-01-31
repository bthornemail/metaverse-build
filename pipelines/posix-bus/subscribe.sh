#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ENV_FILE="${BUS_ENV:-$ROOT/pipelines/posix-bus/bus.env}"

if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  . "$ENV_FILE"
fi

MODE="${BUS_MODE:-fifo}"
BUS_FIFO="${BUS_FIFO:-$ROOT/pipelines/posix-bus/trace.fifo}"
BUS_TCP="${BUS_TCP:-tcp://127.0.0.1:7000}"

NC_BIN="$(command -v lattice-netcat || true)"
if [ -z "$NC_BIN" ]; then
  NC_BIN="$ROOT/../lattice-netcat/lattice-netcat"
fi

case "$MODE" in
  fifo)
    [ -p "$BUS_FIFO" ] || mkfifo "$BUS_FIFO"
    cat "$BUS_FIFO"
    ;;
  tcp)
    host=$(printf "%s" "$BUS_TCP" | sed -n 's|tcp://\([^:/]*\).*|\1|p')
    port=$(printf "%s" "$BUS_TCP" | sed -n 's|tcp://[^:/]*:\([0-9][0-9]*\).*|\1|p')
    : "${host:?missing tcp host}" "${port:?missing tcp port}"
    if [ ! -x "$NC_BIN" ]; then
      echo "lattice-netcat not found" >&2
      exit 1
    fi
    "$NC_BIN" -l -p "$port"
    ;;
  *)
    echo "Unknown BUS_MODE: $MODE" >&2
    exit 2
    ;;
esac
