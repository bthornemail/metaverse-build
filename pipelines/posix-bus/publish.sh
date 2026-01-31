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

if [ -z "${ID_PREFIX+x}" ]; then
  echo "ID_PREFIX must be set" >&2
  exit 2
fi

produce_trace() {
  if [ -f "$ROOT/world/.genesis" ] && [ -x "$ROOT/runtime/trace/sources/run.sh" ]; then
    printf "%s" "${TRACE_INPUT:-}" | sh "$ROOT/runtime/trace/sources/run.sh" world out
  else
    printf "%s" "${TRACE_INPUT:-}"
  fi
}

payload=$(produce_trace | \
  runghc -i"$ROOT/invariants/authority" "$ROOT/invariants/authority/gate/AuthorityGate.hs" 2>/dev/null || true)

if [ -z "$payload" ]; then
  echo "HALT: no publish" >&2
  exit 1
fi

case "$MODE" in
  fifo)
    [ -p "$BUS_FIFO" ] || mkfifo "$BUS_FIFO"
    printf "%s" "$payload" > "$BUS_FIFO"
    ;;
  tcp)
    host=$(printf "%s" "$BUS_TCP" | sed -n 's|tcp://\([^:/]*\).*|\1|p')
    port=$(printf "%s" "$BUS_TCP" | sed -n 's|tcp://[^:/]*:\([0-9][0-9]*\).*|\1|p')
    : "${host:?missing tcp host}" "${port:?missing tcp port}"
    printf "%s" "$payload" | lattice-netcat "$host" "$port"
    ;;
  *)
    echo "Unknown BUS_MODE: $MODE" >&2
    exit 2
    ;;
esac
