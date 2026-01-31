#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REPORT="$ROOT/reports/phase23-transcript.txt"
BUS_ENV="$ROOT/pipelines/posix-bus/bus.env"
TRACE_OUT="$ROOT/pipelines/posix-bus/tcp/state/trace.out"
OBS_FILE="$ROOT/runtime/lattice/peers/observe/observed.jsonl"
HASH_FILE="$ROOT/runtime/lattice/plan/connection-plan.sha"
PIDFILE="$ROOT/pipelines/posix-bus/tcp/state/listen.pid"
PORTFILE="$ROOT/pipelines/posix-bus/tcp/state/listen.port"

{
  echo "# Phase 23 — Live Rebind Transcript"
  echo "Date: $(date -Iseconds)"
  echo "Host: $(hostname)"
  echo

  mkdir -p "$ROOT/pipelines/posix-bus/tcp/state"
  mkdir -p "$(dirname "$OBS_FILE")"
  : > "$TRACE_OUT"
  : > "$OBS_FILE"
  rm -f "$HASH_FILE"
  if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" >/dev/null 2>&1; then
    kill "$(cat "$PIDFILE")" >/dev/null 2>&1 || true
    rm -f "$PIDFILE" "$PORTFILE"
  fi

  echo "## Tick 1 (prefer host-001)"
  echo '{"node":"host-001","addr":"127.0.0.1","bus":7000,"rtt_ms":20}' >> "$ROOT/runtime/lattice/peers/observe/observed.jsonl"
  bash "$ROOT/runtime/lattice/reconcile/tick.sh"
  HASH1=$(cat "$ROOT/runtime/lattice/plan/connection-plan.sha")
  echo "Plan hash: $HASH1"

  echo "## PASS (valid)"
  BUS_ENV="$BUS_ENV" ID_PREFIX=valid TRACE_INPUT="hello" bash "$ROOT/pipelines/posix-bus/publish.sh" 2>&1
  sleep 0.2
  BYTES1=$(wc -c < "$TRACE_OUT" | tr -d ' ')
  echo "Bytes after PASS: $BYTES1"

  echo "## Tick 2 (prefer host-002)"
  echo '{"node":"host-002","addr":"127.0.0.1","bus":7001,"rtt_ms":1}' >> "$ROOT/runtime/lattice/peers/observe/observed.jsonl"
  bash "$ROOT/runtime/lattice/reconcile/tick.sh"
  HASH2=$(cat "$ROOT/runtime/lattice/plan/connection-plan.sha")
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
} > "$REPORT"

sed -n '1,200p' "$REPORT"
