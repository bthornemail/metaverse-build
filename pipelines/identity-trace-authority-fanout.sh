#!/usr/bin/env bash
# Capability: Fan-out topology
# Authority: AuthorityGate (single)
# Justification: ../invariants/authority/INVARIANT.md
# Inputs: stdin + ID_PREFIX
# Outputs: branch outputs
# Trace: yes
# Halt-On-Violation: yes

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TRACE_RUN="$ROOT/runtime/trace/sources/run.sh"
GATE="$ROOT/invariants/authority/gate/AuthorityGate.hs"
QOS="$ROOT/pipelines/qos/qos.sh"
SYNC="$ROOT/pipelines/adapter-sync/run.sh"
RPC="$ROOT/pipelines/adapter-rpc/run.sh"
REPLAY="$ROOT/pipelines/adapter-replay/run.sh"
OUT_DIR="$ROOT/pipelines/fanout"
FIFO="$ROOT/pipelines/pubsub/pubsub.fifo"
STREAM="$ROOT/pipelines/ui/ui.stream"

if [ -z "${ID_PREFIX+x}" ]; then
  echo "ID_PREFIX must be set" >&2
  exit 2
fi

mkdir -p "$OUT_DIR" "$(dirname "$STREAM")"
rm -f "$OUT_DIR/fanout.chainA.out"
[ -p "$FIFO" ] || mkfifo "$FIFO"
: > "$STREAM"

produce_trace() {
  if [ -f "$ROOT/world/.genesis" ] && [ -x "$TRACE_RUN" ]; then
    printf "%s" "${TRACE_INPUT:-}" | sh "$TRACE_RUN" world out
  else
    printf "%s" "${TRACE_INPUT:-}"
  fi
}

# Single gate at root; fan-out to branches
produce_trace | \
  runghc -i"$ROOT/invariants/authority" "$GATE" | \
  tee \
    >(bash "$QOS" slow | bash "$SYNC" | bash "$RPC" | bash "$REPLAY" > "$OUT_DIR/fanout.chainA.out") \
    >(bash "$QOS" smooth | tee "$FIFO" > /dev/null) \
    >(bash "$QOS" fast | tee "$STREAM" > /dev/null) \
  > /dev/null

printf "OK\n"
