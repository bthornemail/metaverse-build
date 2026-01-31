#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FIFO="$ROOT/pipelines/pubsub/pubsub.fifo"
TRACE_RUN="$ROOT/runtime/trace/sources/run.sh"
GATE="$ROOT/invariants/authority/gate/AuthorityGate.hs"

: "${ID_PREFIX:?ID_PREFIX must be set}"

[ -p "$FIFO" ] || mkfifo "$FIFO"

printf "%s" "${TRACE_INPUT:-}" | \
  sh "$TRACE_RUN" world out | \
  runghc -i"$ROOT/invariants/authority" "$GATE" | \
  tee "$FIFO" > /dev/null
