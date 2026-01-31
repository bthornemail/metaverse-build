#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
PORT="${PORT:-9334}"

# Start beacon listener and observer
bash "$ROOT/runtime/lattice/bin/beacon-listen.sh" PORT="$PORT" &
LISTEN_PID=$!

bash "$ROOT/runtime/lattice/bin/peer-observer.sh" &
OBS_PID=$!

# Compile graph/basis/plan periodically
while true; do
  bash "$ROOT/runtime/lattice/bin/graph-basis-compiler.sh"
  sleep 2
  if [ "${ONCE:-}" = "1" ]; then
    break
  fi
 done

kill "$LISTEN_PID" "$OBS_PID" >/dev/null 2>&1 || true
wait "$LISTEN_PID" "$OBS_PID" >/dev/null 2>&1 || true
