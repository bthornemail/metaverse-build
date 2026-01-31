#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
BUS_ENV="$ROOT/pipelines/posix-bus/bus.env"

BUS_MODE=tcp BUS_ENV="$BUS_ENV" bash "$ROOT/pipelines/posix-bus/bus-env.sh" >/dev/null

# Ensure FIFO exists (if used later)
BUS_FIFO=$(grep -E '^BUS_FIFO=' "$BUS_ENV" | cut -d'=' -f2- | tr -d '"')
[ -n "$BUS_FIFO" ] && [ -p "$BUS_FIFO" ] || true

# Ensure TCP listener up
BUS_ENV="$BUS_ENV" bash "$ROOT/pipelines/posix-bus/tcp/listen.sh" >/dev/null
