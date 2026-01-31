#!/usr/bin/env sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TRACE_RUN="$ROOT/runtime/trace/sources/run.sh"
GATE="$ROOT/invariants/authority/gate/AuthorityGate.hs"
PORT="${PORT:-9000}"

: "${ID_PREFIX:?ID_PREFIX must be set}"

printf "%s" "${TRACE_INPUT:-}" | \
  sh "$TRACE_RUN" world out | \
  runghc -i"$ROOT/invariants/authority" "$GATE" | \
  nc localhost "$PORT"
