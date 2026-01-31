#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FIFO="$ROOT/pipelines/pubsub/pubsub.fifo"

[ -p "$FIFO" ] || mkfifo "$FIFO"
cat "$FIFO"
