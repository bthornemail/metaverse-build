#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REPORT="$ROOT/reports/phase31-zones.txt"
STATE_DIR="$ROOT/runtime/zones/state"

IR="$ROOT/world-ir/build/room.ir.json"
BASE_SNAPSHOT="$ROOT/runtime/world/snapshots/room.snapshot.json"
TRACE_DIR="$ROOT/runtime/world/trace"

mkdir -p "$STATE_DIR" "$TRACE_DIR" "$ROOT/reports"

bash "$ROOT/runtime/world/load-ir.sh" "$IR" >/dev/null

# Create entity with spatial zone and logical tags
EVENTS="$TRACE_DIR/zone.lifecycle.jsonl"
cat > "$EVENTS" <<EV
{"type":"ENTITY_CREATE","id":"zone-001","owner":"valid:userA","actor":"valid:userA"}
{"type":"ZONE_MOVE","entity":"zone-001","zone":"zone-a","actor":"valid:userA"}
{"type":"COMPONENT_ATTACH","entity":"zone-001","component":"zone-tags","data":{"tags":["market","player-owned"]},"actor":"valid:userA"}
EV

SNAP_ZONE="$STATE_DIR/zone.snapshot.json"
python3 "$ROOT/runtime/world/apply-event.py" "$BASE_SNAPSHOT" "$EVENTS" "$SNAP_ZONE" >/dev/null

INDEX_PATH=$(python3 "$ROOT/runtime/zones/zone-materialize.py" "$SNAP_ZONE" "$STATE_DIR")

# Route an update event (should target zone-a)
EV_UPDATE="$STATE_DIR/zone.update.json"
cat > "$EV_UPDATE" <<EV
{"type":"COMPONENT_UPDATE","entity":"zone-001","component":"zone-tags","patch":{"tags":["market","player-owned","vip"]},"actor":"valid:userA"}
EV

zone_route_1=$(python3 "$ROOT/runtime/zones/route-event.py" "$SNAP_ZONE" "$EV_UPDATE")

# Move entity to zone-b and re-route
EVENTS2="$TRACE_DIR/zone.lifecycle2.jsonl"
cat > "$EVENTS2" <<EV
{"type":"ZONE_MOVE","entity":"zone-001","zone":"zone-b","actor":"valid:userA"}
EV

SNAP_ZONE2="$STATE_DIR/zone.snapshot2.json"
python3 "$ROOT/runtime/world/apply-event.py" "$SNAP_ZONE" "$EVENTS2" "$SNAP_ZONE2" >/dev/null

zone_route_2=$(python3 "$ROOT/runtime/zones/route-event.py" "$SNAP_ZONE2" "$EV_UPDATE")

{
  echo "# Phase 31 — Hybrid Zone Model"
  echo "Date: $(date -Iseconds)"
  echo "IR: $IR"
  echo "Base Snapshot: $BASE_SNAPSHOT"
  echo "Zone Snapshot: $SNAP_ZONE"
  echo "Zone Index: $INDEX_PATH"
  echo "Route (zone-a): $zone_route_1"
  echo "Route (zone-b): $zone_route_2"
  if [ "$zone_route_1" = "zone-a" ] && [ "$zone_route_2" = "zone-b" ]; then
    echo "PASS: spatial routing deterministic"
  else
    echo "FAIL: spatial routing" 
  fi
} > "$REPORT"

sed -n '1,200p' "$REPORT"

if [ "$zone_route_1" != "zone-a" ] || [ "$zone_route_2" != "zone-b" ]; then
  exit 1
fi
