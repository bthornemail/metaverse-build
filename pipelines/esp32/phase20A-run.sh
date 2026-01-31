#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REPORT="$ROOT/reports/phase20A-transcript.txt"

BROKER="${BROKER:-localhost}"
PORT="${PORT:-1883}"
TOPIC="${TOPIC:-metaverse/trace}"
TTY="${TTY:-}"

cleanup() {
  if [ -f "$ROOT/pipelines/esp32/mosquitto.pid" ]; then
    kill "$(cat "$ROOT/pipelines/esp32/mosquitto.pid")" >/dev/null 2>&1 || true
    rm -f "$ROOT/pipelines/esp32/mosquitto.pid"
  fi
}
trap cleanup EXIT

{
  echo "# Phase 20A — ESP32 MQTT Projection Transcript"
  echo "Date: $(date -Iseconds)"
  echo "Host: $(hostname)"
  echo "Broker: $BROKER:$PORT"
  echo "Topic: $TOPIC"
  echo

  echo "## Start broker"
  BROKER="$BROKER" PORT="$PORT" bash "$ROOT/pipelines/esp32/broker.sh"
  sleep 0.2

  echo "## Start subscriber (host)"
  : > /tmp/phase20A-host-sub.out
  BROKER="$BROKER" PORT="$PORT" TOPIC="$TOPIC" bash "$ROOT/pipelines/esp32/subscribe-host.sh" > /tmp/phase20A-host-sub.out 2>&1 &
  SUB_PID=$!

  if [ -n "$TTY" ]; then
    echo "## Start serial monitor ($TTY)"
    TTY="$TTY" bash "$ROOT/pipelines/esp32/serial-monitor.sh" > /tmp/phase20A-serial.out 2>&1 &
    SER_PID=$!
  fi

  echo "## PASS (valid publishes)"
  ID_PREFIX=valid TRACE_INPUT="hello" BROKER="$BROKER" PORT="$PORT" TOPIC="$TOPIC" \
    bash "$ROOT/pipelines/esp32/publish.sh" 2>&1
  sleep 0.2
  PASS_COUNT=$(wc -l < /tmp/phase20A-host-sub.out | tr -d ' ')

  echo "## FAIL (invalid halts)"
  set +e
  ID_PREFIX="" TRACE_INPUT="hello" BROKER="$BROKER" PORT="$PORT" TOPIC="$TOPIC" \
    bash "$ROOT/pipelines/esp32/publish.sh" 2>&1
  echo "Exit code: $?"
  set -e
  sleep 0.2
  FAIL_COUNT=$(wc -l < /tmp/phase20A-host-sub.out | tr -d ' ')

  echo
  echo "### Host subscriber output"
  if [ -f /tmp/phase20A-host-sub.out ]; then
    echo "Lines after PASS: $PASS_COUNT"
    echo "Lines after FAIL: $FAIL_COUNT"
    echo "Delta (should be 0 on FAIL): $((FAIL_COUNT - PASS_COUNT))"
    echo "Last message:"
    tail -n 1 /tmp/phase20A-host-sub.out
  else
    echo "(no host subscriber output)"
  fi

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
