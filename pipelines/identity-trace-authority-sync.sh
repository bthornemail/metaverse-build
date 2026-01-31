#!/usr/bin/env sh
# Capability: Sync
# Authority: automata-metaverse
# Justification: ../runtime/sync/adapters/typescript/automata-metaverse/ADAPTER-JUSTIFICATION.md
# Inputs: stdin + ID_PREFIX
# Outputs: adapter output
# Trace: yes
# Halt-On-Violation: yes

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TRACE_RUN="$ROOT/runtime/trace/sources/run.sh"
GATE="$ROOT/invariants/authority/gate/AuthorityGate.hs"
ADAPTER="$ROOT/pipelines/adapter-sync/run.sh"
OUT="$ROOT/pipelines/adapter-sync/adapter.out"

: "${ID_PREFIX:?ID_PREFIX must be set}"

TMP="$ROOT/pipelines/adapter-sync/validated.tmp"
rm -f "$TMP"

# Gate first; only invoke adapter if gate succeeds
if printf "%s" "${TRACE_INPUT:-}" | sh "$TRACE_RUN" world out | \
  runghc -i"$ROOT/invariants/authority" "$GATE" > "$TMP"; then
  # Adapter runs only on validated payload
  cat "$TMP" | sh "$ADAPTER" | tee "$OUT" > /dev/null
  rm -f "$TMP"
  printf "OK\n"
else
  rm -f "$TMP"
  exit 1
fi
