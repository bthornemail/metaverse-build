#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GATE="$ROOT/invariants/authority/gate/AuthorityGate.hs"
ADAPTER="$ROOT/pipelines/adapter-sync/run.sh"
TRACE_RUN="$ROOT/runtime/trace/sources/run.sh"

producer() {
  if [ -f "$ROOT/world/.genesis" ] && [ -x "$TRACE_RUN" ]; then
    sh "$TRACE_RUN" world out
  else
    printf "%s" "${TRACE_INPUT:-hello}"
  fi
}

have_pv=0
if command -v pv >/dev/null 2>&1; then
  have_pv=1
fi

probe_throughput() {
  echo "== Probe 1: Throughput (PASS path) =="
  if [ "$have_pv" -eq 1 ]; then
    ID_PREFIX=valid TRACE_INPUT="hello" \
      producer | \
      ID_PREFIX=valid runghc -i"$ROOT/invariants/authority" "$GATE" | \
      pv -f -t -i 0.5 -rab | \
      bash "$ADAPTER" > /dev/null
  else
    echo "pv not available; skipping throughput metrics"
  fi
}

probe_backpressure() {
  echo "== Probe 2: Backpressure (slow adapter) =="
  if [ "$have_pv" -eq 1 ]; then
    ID_PREFIX=valid TRACE_INPUT="hello" \
      producer | \
      ID_PREFIX=valid runghc -i"$ROOT/invariants/authority" "$GATE" | \
      pv -f -t -i 0.5 -L 10k | \
      sh -c 'sleep 0.05; cat' | \
      bash "$ADAPTER" > /dev/null
  else
    echo "pv not available; skipping backpressure metrics"
  fi
}

probe_halt_cost() {
  echo "== Probe 3: HALT cost (FAIL path) =="
  time TRACE_INPUT="hello" \
    printf "%s" "${TRACE_INPUT:-}" | \
    ID_PREFIX="" runghc -i"$ROOT/invariants/authority" "$GATE" > /dev/null || true
}

probe_burst() {
  echo "== Probe 4: Burst handling =="
  if [ "$have_pv" -eq 1 ]; then
    seq 1 1000 | awk '{print "trace-" $1}' | \
      ID_PREFIX=valid runghc -i"$ROOT/invariants/authority" "$GATE" | \
      pv -f -t -i 0.5 -l | \
      bash "$ADAPTER" > /dev/null
  else
    echo "pv not available; skipping burst metrics"
  fi
}

probe_throughput
probe_backpressure
probe_halt_cost
probe_burst
