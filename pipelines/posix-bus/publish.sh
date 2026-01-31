#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BUS_FIFO="${BUS_FIFO:-$ROOT/pipelines/posix-bus/trace.fifo}"

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

[ -p "$BUS_FIFO" ] || mkfifo "$BUS_FIFO"

payload=$(produce_trace | \
  runghc -i"$ROOT/invariants/authority" "$ROOT/invariants/authority/gate/AuthorityGate.hs" 2>/dev/null || true)

if [ -z "$payload" ]; then
  echo "HALT: no publish" >&2
  exit 1
fi

printf "%s" "$payload" > "$BUS_FIFO"
