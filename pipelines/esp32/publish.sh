#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# Uses existing authority-gated MQTT publish
if [ -z "${ID_PREFIX+x}" ]; then
  echo "ID_PREFIX must be set" >&2
  exit 2
fi
TRACE_INPUT="${TRACE_INPUT:-}"
BROKER="${BROKER:-localhost}"
PORT="${PORT:-1883}"
TOPIC="${TOPIC:-metaverse/trace}"

ID_PREFIX="$ID_PREFIX" TRACE_INPUT="$TRACE_INPUT" BROKER="$BROKER" PORT="$PORT" TOPIC="$TOPIC" \
  bash "$ROOT/pipelines/mqtt/publish.sh"
