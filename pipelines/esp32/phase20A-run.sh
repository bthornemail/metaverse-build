#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REPORT="$ROOT/reports/phase20A-transcript.txt"
BUS_FIFO="${BUS_FIFO:-$ROOT/pipelines/posix-bus/trace.fifo}"
TTY="${TTY:-}"

{
  echo "# Phase 20A — ESP32 POSIX Projection Transcript"
  echo "Date: $(date -Iseconds)"
  echo "Host: $(hostname)"
  echo "Bus FIFO: $BUS_FIFO"
  echo

  echo "## Start subscriber (host)"
  : > /tmp/phase20A-host-sub.out
  BUS_FIFO="$BUS_FIFO" bash "$ROOT/pipelines/posix-bus/subscribe.sh" > /tmp/phase20A-host-sub.out 2>&1 &
  SUB_PID=$!

  if [ -n "$TTY" ]; then
    echo "## Start serial monitor ($TTY)"
    TTY="$TTY" bash "$ROOT/pipelines/esp32/serial-monitor.sh" > /tmp/phase20A-serial.out 2>&1 &
    SER_PID=$!
  fi

  echo "## PASS (valid publishes)"
  BUS_FIFO="$BUS_FIFO" ID_PREFIX=valid TRACE_INPUT="hello" \
    bash "$ROOT/pipelines/posix-bus/publish.sh" 2>&1
  sleep 0.2
  PASS_COUNT=$(wc -l < /tmp/phase20A-host-sub.out | tr -d ' ')

  echo "## FAIL (invalid halts)"
  set +e
  BUS_FIFO="$BUS_FIFO" ID_PREFIX="" TRACE_INPUT="hello" \
    bash "$ROOT/pipelines/posix-bus/publish.sh" 2>&1
  echo "Exit code: $?"
  set -e
  sleep 0.2
  FAIL_COUNT=$(wc -l < /tmp/phase20A-host-sub.out | tr -d ' ')

  echo
  echo "### Host subscriber output"
  echo "Lines after PASS: $PASS_COUNT"
  echo "Lines after FAIL: $FAIL_COUNT"
  echo "Delta (should be 0 on FAIL): $((FAIL_COUNT - PASS_COUNT))"
  echo "Last message:"
  tail -n 1 /tmp/phase20A-host-sub.out

  if [ -n "$TTY" ]; then
    echo
    echo "### Serial monitor output"
    if [ -f /tmp/phase20A-serial.out ]; then
      sed -n '1,5p' /tmp/phase20A-serial.out
    else
      echo "(no serial output)"
    fi
  fi

  kill "$SUB_PID" >/dev/null 2>&1 || true
  if [ -n "${SER_PID:-}" ]; then
    kill "$SER_PID" >/dev/null 2>&1 || true
  fi
} > "$REPORT"

sed -n '1,200p' "$REPORT"
