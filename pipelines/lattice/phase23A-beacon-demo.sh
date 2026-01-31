#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REPORT="$ROOT/reports/phase23A-beacon-demo.txt"
OBS_FILE="$ROOT/runtime/lattice/peers/observe/observed.jsonl"
BEACON_LOG="$ROOT/runtime/lattice/peers/observe/beacons.log"
TRACE_OUT="$ROOT/pipelines/posix-bus/tcp/state/trace.out"
BUS_ENV="$ROOT/pipelines/posix-bus/bus.env"
PIDFILE="$ROOT/pipelines/posix-bus/tcp/state/listen.pid"
PORTFILE="$ROOT/pipelines/posix-bus/tcp/state/listen.port"
HASH_FILE="$ROOT/runtime/lattice/plan/connection-plan.sha"

HOST_ADDR="${HOST_ADDR:-127.0.0.1}"
BEACON_PORT="${BEACON_PORT:-9335}"

mkdir -p "$(dirname "$OBS_FILE")" "$ROOT/reports" "$ROOT/pipelines/posix-bus/tcp/state"
: > "$OBS_FILE"
: > "$BEACON_LOG"
: > "$TRACE_OUT"
rm -f "$HASH_FILE"

if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" >/dev/null 2>&1; then
  kill "$(cat "$PIDFILE")" >/dev/null 2>&1 || true
  rm -f "$PIDFILE" "$PORTFILE"
fi

# Ensure no stale beacon listeners
pkill -f "$ROOT/runtime/lattice/bin/beacon-listen.sh" >/dev/null 2>&1 || true
pkill -f "$ROOT/runtime/lattice/compiler/peer-observer.sh" >/dev/null 2>&1 || true
pkill -f "lattice-netcat.*${BEACON_PORT}" >/dev/null 2>&1 || true
pkill -f "nc -u -l -p $BEACON_PORT" >/dev/null 2>&1 || true
pkill -f "nc -l -p $BEACON_PORT" >/dev/null 2>&1 || true

{
  echo "# Phase 23A — Beacon-Driven Basis Flip Demo"
  echo "Date: $(date -Iseconds)"
  echo "Host: $(hostname)"
  echo "Beacon port: $BEACON_PORT"
  echo

  echo "## Start beacon listener + observer"
  DISCOVERY_MODE=tcp DISCOVERY_TCP_IMPL=socat KEEP_OPEN=1 PORT="$BEACON_PORT" BEACON_OUT="$BEACON_LOG" \
    bash "$ROOT/runtime/lattice/bin/beacon-listen.sh" &
  LISTEN_PID=$!
  BEACON_IN="$BEACON_LOG" bash "$ROOT/runtime/lattice/compiler/peer-observer.sh" &
  OBS_PID=$!
  sleep 0.5

  echo "## Beacon 1 (host-001, rtt=20, bus=7000)"
  DISCOVERY_MODE=tcp DISCOVERY_TCP_IMPL=devtcp HOST="$HOST_ADDR" PORT="$BEACON_PORT" NODE="host-001" ADDR="$HOST_ADDR" BUS_PORT=7000 RTT_MS=20 \
    bash "$ROOT/runtime/lattice/bin/beacon-send.sh"
  sleep 0.5
  echo "Beacons log (after beacon 1):"
  sed -n '1,2p' "$BEACON_LOG"
  echo "Observed (after beacon 1):"
  sed -n '1,2p' "$OBS_FILE"
  bash "$ROOT/runtime/lattice/reconcile/tick.sh"
  HASH1=$(cat "$HASH_FILE")
  echo "Plan hash: $HASH1"

  echo "## PASS (valid)"
  BUS_ENV="$BUS_ENV" ID_PREFIX=valid TRACE_INPUT="hello" bash "$ROOT/pipelines/posix-bus/publish.sh" 2>&1
  sleep 0.2
  BYTES1=$(wc -c < "$TRACE_OUT" | tr -d ' ')
  echo "Bytes after PASS: $BYTES1"

  echo "## Beacon 2 (host-002, rtt=1, bus=7001)"
  DISCOVERY_MODE=tcp DISCOVERY_TCP_IMPL=devtcp HOST="$HOST_ADDR" PORT="$BEACON_PORT" NODE="host-002" ADDR="$HOST_ADDR" BUS_PORT=7001 RTT_MS=1 \
    bash "$ROOT/runtime/lattice/bin/beacon-send.sh"
  sleep 0.5
  echo "Beacons log (after beacon 2):"
  sed -n '1,3p' "$BEACON_LOG"
  echo "Observed (after beacon 2):"
  sed -n '1,3p' "$OBS_FILE"
  bash "$ROOT/runtime/lattice/reconcile/tick.sh"
  HASH2=$(cat "$HASH_FILE")
  echo "Plan hash: $HASH2"

  echo "## FAIL (invalid halts)"
  set +e
  BUS_ENV="$BUS_ENV" ID_PREFIX="" TRACE_INPUT="hello" bash "$ROOT/pipelines/posix-bus/publish.sh" 2>&1
  echo "Exit code: $?"
  set -e
  sleep 0.2
  BYTES2=$(wc -c < "$TRACE_OUT" | tr -d ' ')
  echo "Bytes after FAIL: $BYTES2"
  echo "Delta (should be 0 on FAIL): $((BYTES2 - BYTES1))"

  echo "## Plan change"
  if [ "$HASH1" != "$HASH2" ]; then
    echo "Plan changed: yes"
  else
    echo "Plan changed: no"
  fi

  kill "$LISTEN_PID" "$OBS_PID" >/dev/null 2>&1 || true
} > "$REPORT"

sed -n '1,200p' "$REPORT"
