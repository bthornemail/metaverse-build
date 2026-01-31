#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLAN="${PLAN_PATH:-$ROOT/runtime/lattice/state/plan/connection-plan.json}"
OUT="${BUS_ENV:-$ROOT/pipelines/posix-bus/bus.env}"

# Default mode
MODE="${BUS_MODE:-fifo}"

BUS_FIFO="${BUS_FIFO:-$ROOT/pipelines/posix-bus/trace.fifo}"
BUS_TCP="${BUS_TCP:-tcp://127.0.0.1:7000}"

if [ -f "$PLAN" ]; then
  # Prefer bus from discovery plan if present (trace_tcp or trace_fifo)
  TCP=$(sed -n 's/.*"trace_tcp":"\([^"]*\)".*/\1/p' "$PLAN" | head -n 1 || true)
  FIFO=$(sed -n 's/.*"trace_fifo":"\([^"]*\)".*/\1/p' "$PLAN" | head -n 1 || true)
  if [ -n "$TCP" ]; then BUS_TCP="$TCP"; fi
  if [ -n "$FIFO" ]; then BUS_FIFO="$FIFO"; fi
fi

cat > "$OUT" <<ENV
BUS_MODE="$MODE"
BUS_FIFO="$BUS_FIFO"
BUS_TCP="$BUS_TCP"
ENV

echo "Wrote $OUT"
