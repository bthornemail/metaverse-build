#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REPORT="$ROOT/reports/phase32A-migration.txt"
STATE_DIR="$ROOT/runtime/zones/state"
TRACE_DIR="$ROOT/runtime/world/trace"

IR="$ROOT/world-ir/build/room.ir.json"
BASE_SNAPSHOT="$ROOT/runtime/world/snapshots/room.snapshot.json"

mkdir -p "$STATE_DIR" "$TRACE_DIR" "$ROOT/reports"

bash "$ROOT/runtime/world/load-ir.sh" "$IR" >/dev/null

# Build a base snapshot with an entity in zone-a
EVENTS="$TRACE_DIR/zone.migration.jsonl"
cat > "$EVENTS" <<EV
{"type":"ENTITY_CREATE","id":"migr-001","owner":"valid:userA","actor":"valid:userA"}
{"type":"ZONE_MOVE","entity":"migr-001","zone":"zone-a","actor":"valid:userA"}
EV

SNAP_ZONE="$STATE_DIR/migration.source.json"
python3 "$ROOT/runtime/world/apply-event.py" "$BASE_SNAPSHOT" "$EVENTS" "$SNAP_ZONE" >/dev/null

# Materialize zone snapshots
INDEX_PATH=$(python3 "$ROOT/runtime/zones/zone-materialize.py" "$SNAP_ZONE" "$STATE_DIR")
SRC_ZONE_SNAP="$STATE_DIR/zone-a.snapshot.json"

# Create empty dest zone snapshot if missing
DEST_ZONE_SNAP="$STATE_DIR/zone-b.snapshot.json"
if [ ! -f "$DEST_ZONE_SNAP" ]; then
  python3 - <<PY
import json
snap = json.load(open("$SNAP_ZONE","r"))
zone = {"world": snap.get("world"), "zone": "zone-b", "state": {"entities": []}, "source_snapshot_hash": snap.get("source_snapshot_hash")}
open("$DEST_ZONE_SNAP","w").write(json.dumps(zone, sort_keys=True, separators=(",", ":")))
PY
fi

TRANSFER="$STATE_DIR/transfer.json"
SRC_OUT="$STATE_DIR/zone-a.after.json"
DEST_OUT="$STATE_DIR/zone-b.after.json"

hash_transfer=$(python3 "$ROOT/runtime/zones/migrate-entity.py" "$SRC_ZONE_SNAP" "migr-001" "zone-b" "$TRANSFER" "$SRC_OUT")
hash_dest=$(python3 "$ROOT/runtime/zones/apply-migration.py" "$DEST_ZONE_SNAP" "$TRANSFER" "$DEST_OUT")

# Re-run to confirm determinism
TRANSFER2="$STATE_DIR/transfer2.json"
SRC_OUT2="$STATE_DIR/zone-a.after2.json"
DEST_OUT2="$STATE_DIR/zone-b.after2.json"

hash_transfer2=$(python3 "$ROOT/runtime/zones/migrate-entity.py" "$SRC_ZONE_SNAP" "migr-001" "zone-b" "$TRANSFER2" "$SRC_OUT2")
hash_dest2=$(python3 "$ROOT/runtime/zones/apply-migration.py" "$DEST_ZONE_SNAP" "$TRANSFER2" "$DEST_OUT2")

{
  echo "# Phase 32A — Cross-Zone Migration"
  echo "Date: $(date -Iseconds)"
  echo "IR: $IR"
  echo "Index: $INDEX_PATH"
  echo "Source Zone Snapshot: $SRC_ZONE_SNAP"
  echo "Dest Zone Snapshot: $DEST_ZONE_SNAP"
  echo "Transfer Hash: $hash_transfer"
  echo "Transfer Hash (2): $hash_transfer2"
  echo "Dest Hash: $hash_dest"
  echo "Dest Hash (2): $hash_dest2"
  if [ "$hash_transfer" = "$hash_transfer2" ] && [ "$hash_dest" = "$hash_dest2" ]; then
    echo "PASS: deterministic migration"
  else
    echo "FAIL: deterministic migration"
  fi
} > "$REPORT"

sed -n '1,200p' "$REPORT"

if [ "$hash_transfer" != "$hash_transfer2" ] || [ "$hash_dest" != "$hash_dest2" ]; then
  exit 1
fi
