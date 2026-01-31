#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-}"
SOURCE="${2:-}"
OUT_LOG="${3:-}"

if [ -z "$MODE" ] || [ -z "$SOURCE" ] || [ -z "$OUT_LOG" ]; then
  echo "usage: receive.sh <fifo|tcp> <source> <out_log>" >&2
  exit 2
fi

mkdir -p "$(dirname "$OUT_LOG")"

append_loop() {
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    echo "$line" >> "$OUT_LOG"
  done
}

case "$MODE" in
  fifo)
    if [ ! -p "$SOURCE" ]; then
      mkfifo "$SOURCE"
    fi
    append_loop < "$SOURCE"
    ;;
  tcp)
    port="$SOURCE"
    if command -v rg >/dev/null 2>&1; then
      if nc -h 2>&1 | rg -q -- "-p"; then
        nc -l -p "$port" | append_loop
      else
        nc -l "$port" | append_loop
      fi
    else
      if nc -h 2>&1 | grep -q -- "-p"; then
        nc -l -p "$port" | append_loop
      else
        nc -l "$port" | append_loop
      fi
    fi
    ;;
  *)
    echo "unknown mode: $MODE" >&2
    exit 2
    ;;
 esac
