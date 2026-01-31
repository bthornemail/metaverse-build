#!/usr/bin/env bash
set -euo pipefail

TTY="${TTY:-/dev/ttyUSB0}"
BAUD="${BAUD:-115200}"

if [ ! -e "$TTY" ]; then
  echo "TTY not found: $TTY" >&2
  exit 1
fi

stty -F "$TTY" "$BAUD" raw -echo
cat "$TTY"
