#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-}"
TARGET="${2:-}"

if [ -z "$MODE" ] || [ -z "$TARGET" ]; then
  echo "usage: send.sh <fifo|tcp> <target>" >&2
  exit 2
fi

case "$MODE" in
  fifo)
    cat > "$TARGET"
    ;;
  tcp)
    host="${TARGET%:*}"
    port="${TARGET#*:}"
    nc "$host" "$port"
    ;;
  *)
    echo "unknown mode: $MODE" >&2
    exit 2
    ;;
 esac
