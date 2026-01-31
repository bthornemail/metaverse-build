#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TOPIC="${TOPIC:-metaverse/trace}"
BROKER="${BROKER:-localhost}"
PORT="${PORT:-1883}"
FIFO="$ROOT/pipelines/mqtt/mqtt.mock.fifo"

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

# Produce trace through authority gate (no adapters)
payload=$(produce_trace | \
  runghc -i"$ROOT/invariants/authority" "$ROOT/invariants/authority/gate/AuthorityGate.hs" 2>/dev/null || true)

if [ -z "$payload" ]; then
  echo "HALT: no publish" >&2
  exit 1
fi

if command -v mosquitto_pub >/dev/null 2>&1; then
  printf "%s" "$payload" | mosquitto_pub -h "$BROKER" -p "$PORT" -t "$TOPIC" -s
else
  [ -p "$FIFO" ] || mkfifo "$FIFO"
  printf "%s\n" "$payload" > "$FIFO"
fi
