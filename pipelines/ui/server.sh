#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-8080}"
STREAM="$(cd "$(dirname "$0")/.." && pwd)/ui/ui.stream"

: > "$STREAM"

while true; do
  printf "HTTP/1.1 200 OK\r\n\r\n"
  cat "$STREAM"
done | nc -l "$PORT"
