#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLAN="$ROOT/runtime/lattice/state/plan/connection-plan.json"
OUT="${OUT:-$ROOT/runtime/lattice/state/plan/device-plan.json}"

HOST_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if ($i=="src") {print $(i+1); exit}}')
HOST_IP=${HOST_IP:-127.0.0.1}

BUS_PORT=$(printf "%s" "$PLAN" | sed -n 's/.*"trace_tcp":"tcp:\/\/[^:]*:\([0-9][0-9]*\)".*/\1/p' | head -n 1)
BUS_PORT=${BUS_PORT:-7000}

cat > "$OUT" <<JSON
{"node_id":"host-001","buses":{"trace":{"mode":"tcp","addr":"$HOST_IP","port":$BUS_PORT}}}
JSON

echo "Wrote $OUT"
