#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
GRAPH="$ROOT/runtime/lattice/graph/peergraph.json"
BASIS="$ROOT/runtime/lattice/graph/basis.json"
PLAN="$ROOT/runtime/lattice/plan/connection-plan.json"
DEVICE="$ROOT/runtime/lattice/plan/device-plan.json"

[ -d "$(dirname "$PLAN")" ] || mkdir -p "$(dirname "$PLAN")"

HOST_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if ($i=="src") {print $(i+1); exit}}')
HOST_IP=${HOST_IP:-127.0.0.1}

lookup_peer() {
  local peer="$1"
  line=$(grep -m1 "\"id\":\"$peer\"" "$GRAPH" || true)
  addr=$(printf "%s" "$line" | sed -n 's/.*"addr":"\([^"]*\)".*/\1/p')
  bus=$(printf "%s" "$line" | sed -n 's/.*"bus":\([0-9][0-9]*\).*/\1/p')
  printf "%s\t%s\n" "$addr" "$bus"
}

# Build connection plan from basis
{
  echo '{'
  echo '  "version": "plan-1",'
  echo '  "attachments": ['
  first=1
  while IFS= read -r line; do
    peer=$(printf "%s" "$line" | sed -n 's/.*"peer":"\([^"]*\)".*/\1/p')
    [ -n "$peer" ] || continue
    info=$(lookup_peer "$peer")
    addr=$(printf "%s" "$info" | cut -f1)
    bus=$(printf "%s" "$info" | cut -f2)
    addr=${addr:-$HOST_IP}
    bus=${bus:-7000}
    [ $first -eq 0 ] && printf ',\n'
    first=0
    printf '    {"name":"bus-%s","kind":"bus","peer":"%s","trace_fifo":"%s","trace_tcp":"tcp://%s:%s"}' "$peer" "$peer" "$ROOT/pipelines/posix-bus/trace.fifo" "$addr" "$bus"
  done < "$BASIS"
  echo
  echo '  ]'
  echo '}'
} > "$PLAN"

# Device plan (projection only)
sel_peer=$(sed -n 's/.*"peer":"\([^"]*\)".*/\1/p' "$BASIS" | head -n 1)
info=$(lookup_peer "$sel_peer")
sel_addr=$(printf "%s" "$info" | cut -f1)
sel_bus=$(printf "%s" "$info" | cut -f2)
sel_addr=${sel_addr:-$HOST_IP}
sel_bus=${sel_bus:-7000}
cat > "$DEVICE" <<JSON
{"node_id":"host-001","buses":{"trace":{"mode":"tcp","addr":"$sel_addr","port":$sel_bus}}}
JSON
