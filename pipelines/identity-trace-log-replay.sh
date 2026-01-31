#!/usr/bin/env sh
# Capability: Trace
# Authority: universal-life-protocol
# Justification: ../runtime/trace/JUSTIFICATION.md
# Inputs: stdin + ID_PREFIX
# Outputs: log + replay
# Trace: yes
# Halt-On-Violation: yes

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TRACE_RUN="$ROOT/runtime/trace/sources/run.sh"
LOG_OUT="$ROOT/runtime/log/trace.log"
REPLAY="$ROOT/runtime/replay/sources/decode_trace.sh"
GATE="$ROOT/invariants/authority/gate/AuthorityGate.hs"

: "${ID_PREFIX:?ID_PREFIX must be set}"

# Identity → Trace → Authority Gate → Immutable-Log → Replay
# Note: This is a thin integration slice with no adapter integration.

printf "%s" "${TRACE_INPUT:-}" | \
  sh "$TRACE_RUN" world out | \
  runghc -i"$ROOT/invariants/authority" "$GATE" | \
  tee "$LOG_OUT" > /dev/null

# Replay (best-effort; requires ULP v1.1 decoder semantics)
if [ -x "$REPLAY" ]; then
  sh "$REPLAY" "$LOG_OUT" "$ROOT/runtime/replay/out" || true
fi

printf "OK\n"
