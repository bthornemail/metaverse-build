#!/usr/bin/env python3
import json
import os
import sys
from hashlib import sha256

def fail(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)

if len(sys.argv) < 3:
    fail("usage: zone-materialize.py <snapshot.json> <out_dir>")

snap_path = sys.argv[1]
out_dir = sys.argv[2]

with open(snap_path, "r") as fh:
    snap = json.load(fh)

state = snap.get("state", {})
entities = state.get("entities", [])
if not isinstance(entities, list):
    fail("invalid snapshot: entities not list")

zones = {}
for ent in entities:
    if not isinstance(ent, dict):
        continue
    zone = ent.get("zone")
    if not isinstance(zone, str) or not zone:
        zone = "zone-unknown"
    zones.setdefault(zone, []).append(ent)

# deterministic ordering by entity id
for zone, ents in zones.items():
    ents.sort(key=lambda e: str(e.get("id")))

snap_bytes = json.dumps(snap, sort_keys=True, separators=(",", ":")).encode("utf-8")
source_hash = sha256(snap_bytes).hexdigest()

os.makedirs(out_dir, exist_ok=True)
index = {"source_snapshot": snap_path, "source_hash": source_hash, "zones": {}}

for zone, ents in zones.items():
    zone_snap = {
        "world": snap.get("world"),
        "zone": zone,
        "state": {"entities": ents},
        "source_snapshot_hash": source_hash,
    }
    zone_path = os.path.join(out_dir, f"{zone}.snapshot.json")
    with open(zone_path, "w") as fh:
        fh.write(json.dumps(zone_snap, sort_keys=True, separators=(",", ":")))
    index["zones"][zone] = {
        "snapshot": zone_path,
        "entity_count": len(ents),
    }

index_path = os.path.join(out_dir, "zone-index.json")
with open(index_path, "w") as fh:
    fh.write(json.dumps(index, sort_keys=True, separators=(",", ":")))

print(index_path)
