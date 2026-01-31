#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BUS_FIFO="${BUS_FIFO:-$ROOT/pipelines/posix-bus/trace.fifo}"

[ -p "$BUS_FIFO" ] || mkfifo "$BUS_FIFO"
cat "$BUS_FIFO"
