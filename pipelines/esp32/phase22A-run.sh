#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REPORT="$ROOT/reports/phase22A-transcript.txt"
BUS_ENV="${BUS_ENV:-$ROOT/pipelines/posix-bus/bus.env}"
TTY="${TTY:-}"

# Ensure bus env is current and set to tcp
BUS_MODE=tcp BUS_ENV="$BUS_ENV" bash "$ROOT/pipelines/posix-bus/bus-env.sh" >/dev/null

{
  echo "# Phase 22A — ESP32 TCP Bus Transcript"
  echo "Date: $(date -Iseconds)"
  echo "Host: $(hostname)"
  echo "Bus env: $BUS_ENV"
  echo

  echo "## Start TCP bus listener"
  BUS_ENV="$BUS_ENV" bash "$ROOT/pipelines/posix-bus/tcp/listen.sh"

  echo "## Start subscriber (host capture)"
  : > /tmp/phase22A-host-sub.out
  TRACE_OUT="$ROOT/pipelines/posix-bus/tcp/state/trace.out"
  tail -n +1 -F "$TRACE_OUT" > /tmp/phase22A-host-sub.out 2>&1 &
  SUB_PID=$!
  sleep 0.2

  if [ -n "$TTY" ]; then
    echo "## Start serial monitor ($TTY)"
    TTY="$TTY" bash "$ROOT/pipelines/esp32/serial-monitor.sh" > /tmp/phase22A-serial.out 2>&1 &
    SER_PID=$!
  fi

  echo "## PASS (valid publishes)"
  BUS_ENV="$BUS_ENV" ID_PREFIX=valid TRACE_INPUT="hello" \
    bash "$ROOT/pipelines/posix-bus/publish.sh" 2>&1
  sleep 0.2
  PASS_COUNT=$(wc -c < /tmp/phase22A-host-sub.out | tr -d ' ')

  echo "## FAIL (invalid halts)"
  set +e
  BUS_ENV="$BUS_ENV" ID_PREFIX="" TRACE_INPUT="hello" \
    bash "$ROOT/pipelines/posix-bus/publish.sh" 2>&1
  echo "Exit code: $?"
  set -e
  sleep 0.2
  FAIL_COUNT=$(wc -c < /tmp/phase22A-host-sub.out | tr -d ' ')

  echo
  echo "### Host subscriber output"
  echo "Bytes after PASS: $PASS_COUNT"
  echo "Bytes after FAIL: $FAIL_COUNT"
  echo "Delta (should be 0 on FAIL): $((FAIL_COUNT - PASS_COUNT))"
  echo "Last message:"
  tail -n 1 /tmp/phase22A-host-sub.out

  if [ -n "$TTY" ]; then
    echo
    echo "### Serial monitor output"
    if [ -f /tmp/phase22A-serial.out ]; then
      sed -n '1,5p' /tmp/phase22A-serial.out
    else
      echo "(no serial output)"
    fi
  fi

  kill "$SUB_PID" >/dev/null 2>&1 || true
  if [ -n "${SER_PID:-}" ]; then
    kill "$SER_PID" >/dev/null 2>&1 || true
  fi

  # Stop TCP listener if running
  PIDFILE="$ROOT/pipelines/posix-bus/tcp/state/listen.pid"
  if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" >/dev/null 2>&1; then
    kill "$(cat "$PIDFILE")" >/dev/null 2>&1 || true
    rm -f "$PIDFILE"
  fi
} > "$REPORT"

sed -n '1,200p' "$REPORT"
