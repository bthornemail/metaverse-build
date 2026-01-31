#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLAN="$ROOT/runtime/lattice/plan/connection-plan.json"
OUT="${OUT:-$ROOT/runtime/lattice/plan/device-plan.json}"

TRACE_TCP=$(sed -n 's/.*"trace_tcp":"\([^"]*\)".*/\1/p' "$PLAN" | head -n 1)
BUS_HOST=$(printf "%s" "$TRACE_TCP" | sed -n 's#tcp://\([^:]*\):.*#\1#p')
BUS_PORT=$(printf "%s" "$TRACE_TCP" | sed -n 's#tcp://[^:]*:\([0-9][0-9]*\)#\1#p')
BUS_HOST=${BUS_HOST:-127.0.0.1}
BUS_PORT=${BUS_PORT:-7000}

cat > "$OUT" <<JSON
{"node_id":"host-001","buses":{"trace":{"mode":"tcp","addr":"$BUS_HOST","port":$BUS_PORT}}}
JSON

echo "Wrote $OUT"
