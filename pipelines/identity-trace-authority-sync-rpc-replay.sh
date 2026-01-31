#!/usr/bin/env bash
# Capability: Sync + RPC + Replay
# Authority: automata-metaverse / bicf-production
# Justification: ../runtime/sync/adapters/typescript/automata-metaverse/ADAPTER-JUSTIFICATION.md
# Inputs: stdin + ID_PREFIX
# Outputs: chained adapter output
# Trace: yes
# Halt-On-Violation: yes

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TRACE_RUN="$ROOT/runtime/trace/sources/run.sh"
GATE="$ROOT/invariants/authority/gate/AuthorityGate.hs"
SYNC="$ROOT/pipelines/adapter-sync/run.sh"
RPC="$ROOT/pipelines/adapter-rpc/run.sh"
REPLAY="$ROOT/pipelines/adapter-replay/run.sh"
OUT="$ROOT/pipelines/adapter-chain/chain3.out"

: "${ID_PREFIX:?ID_PREFIX must be set}"

mkdir -p "$ROOT/pipelines/adapter-chain"
rm -f "$OUT"

# Gate first; then Sync → RPC → Replay
printf "%s" "${TRACE_INPUT:-}" | \
  sh "$TRACE_RUN" world out | \
  runghc -i"$ROOT/invariants/authority" "$GATE" | \
  bash "$SYNC" | \
  bash "$RPC" | \
  bash "$REPLAY" | \
  tee "$OUT" > /dev/null

printf "OK\n"
