#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REPORT="$ROOT/reports/phase24F1-transcript.txt"
BEACON_PORT="${BEACON_PORT:-9340}"
HOST_ADDR="${HOST_ADDR:-127.0.0.1}"

OBS_FILE="$ROOT/runtime/lattice/peers/observe/observed.jsonl"
BEACON_LOG="$ROOT/runtime/lattice/peers/observe/beacons.log"

mkdir -p "$(dirname "$OBS_FILE")" "$ROOT/reports"
: > "$OBS_FILE"
: > "$BEACON_LOG"

# reset plan history index
rm -rf "$ROOT/projections/mind-git/plan-history" || true

{
  echo "# Phase 24F.1 — Controlled Basis Flip"
  echo "Date: $(date -Iseconds)"
  echo "Host: $(hostname)"
  echo "Beacon port: $BEACON_PORT"
  echo

  echo "## Start beacon listener + observer"
  pkill -f "$ROOT/runtime/lattice/bin/beacon-listen.sh" >/dev/null 2>&1 || true
  pkill -f "$ROOT/runtime/lattice/compiler/peer-observer.sh" >/dev/null 2>&1 || true
  pkill -f "lattice-netcat.*${BEACON_PORT}" >/dev/null 2>&1 || true
  pkill -f "nc -u -l -p $BEACON_PORT" >/dev/null 2>&1 || true
  pkill -f "nc -l -p $BEACON_PORT" >/dev/null 2>&1 || true
  DISCOVERY_MODE=tcp DISCOVERY_TCP_IMPL=socat KEEP_OPEN=1 PORT="$BEACON_PORT" BEACON_OUT="$BEACON_LOG" \
    bash "$ROOT/runtime/lattice/bin/beacon-listen.sh" &
  LISTEN_PID=$!
  BEACON_IN="$BEACON_LOG" bash "$ROOT/runtime/lattice/compiler/peer-observer.sh" &
  OBS_PID=$!
  sleep 0.5

  echo "## Phase A: prefer host-a"
  DISCOVERY_MODE=tcp DISCOVERY_TCP_IMPL=devtcp HOST="$HOST_ADDR" PORT="$BEACON_PORT" NODE="host-a" ADDR="$HOST_ADDR" BUS_PORT=7000 RTT_MS=1 \
    bash "$ROOT/runtime/lattice/bin/beacon-send.sh"
  DISCOVERY_MODE=tcp DISCOVERY_TCP_IMPL=devtcp HOST="$HOST_ADDR" PORT="$BEACON_PORT" NODE="host-b" ADDR="$HOST_ADDR" BUS_PORT=7001 RTT_MS=50 \
    bash "$ROOT/runtime/lattice/bin/beacon-send.sh"
  sleep 0.8
  bash "$ROOT/runtime/lattice/reconcile/tick.sh"
  echo "Beacons log (A):"
  sed -n '1,3p' "$BEACON_LOG"
  echo "Observed (A):"
  sed -n '1,3p' "$OBS_FILE"
  bash "$ROOT/pipelines/mind-git/run.sh" >/dev/null

  echo "## Phase B: flip to host-b"
  DISCOVERY_MODE=tcp DISCOVERY_TCP_IMPL=devtcp HOST="$HOST_ADDR" PORT="$BEACON_PORT" NODE="host-a" ADDR="$HOST_ADDR" BUS_PORT=7000 RTT_MS=50 \
    bash "$ROOT/runtime/lattice/bin/beacon-send.sh"
  DISCOVERY_MODE=tcp DISCOVERY_TCP_IMPL=devtcp HOST="$HOST_ADDR" PORT="$BEACON_PORT" NODE="host-b" ADDR="$HOST_ADDR" BUS_PORT=7001 RTT_MS=1 \
    bash "$ROOT/runtime/lattice/bin/beacon-send.sh"
  sleep 0.8
  bash "$ROOT/runtime/lattice/reconcile/tick.sh"
  echo "Beacons log (B):"
  sed -n '1,5p' "$BEACON_LOG"
  echo "Observed (B):"
  sed -n '1,5p' "$OBS_FILE"
  bash "$ROOT/pipelines/mind-git/run.sh" >/dev/null

  echo "## Plan History (latest)"
  sed -n '1,200p' "$ROOT/projections/mind-git/reports/plan-history.md"

  kill "$LISTEN_PID" "$OBS_PID" >/dev/null 2>&1 || true
} > "$REPORT"

sed -n '1,200p' "$REPORT"
