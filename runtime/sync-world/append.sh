#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STATE_DIR="$ROOT/runtime/sync-world/state"
LOG_DIR="$STATE_DIR/logs"

peer="${1:-}"
seq="${2:-}"
event_file="${3:-}"

if [ -z "$peer" ] || [ -z "$seq" ] || [ -z "$event_file" ]; then
  echo "usage: append.sh <peer> <seq> <event.json|->" >&2
  exit 2
fi

mkdir -p "$LOG_DIR"

if [ "$event_file" = "-" ]; then
  event_json=$(cat)
else
  event_json=$(cat "$event_file")
fi

if [ -z "$event_json" ]; then
  echo "event payload required" >&2
  exit 2
fi

printf '{"peer":"%s","seq":%s,"event":%s}\n' "$peer" "$seq" "$event_json" >> "$LOG_DIR/${peer}.jsonl"
