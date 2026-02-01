#!/usr/bin/env python3
import json
import sys
from hashlib import sha256

def fail(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)

if len(sys.argv) < 4:
    fail("usage: apply-migration.py <dest_zone_snapshot> <transfer.json> <out_dest_snapshot>")

dest_path = sys.argv[1]
transfer_path = sys.argv[2]
out_dest = sys.argv[3]

with open(dest_path, "r") as fh:
    dest = json.load(fh)

with open(transfer_path, "r") as fh:
    transfer = json.load(fh)

entity = transfer.get("entity")
if not isinstance(entity, dict):
    fail("invalid transfer: missing entity")

dest_zone = transfer.get("to")
if not isinstance(dest_zone, str) or not dest_zone:
    fail("invalid transfer: missing dest zone")

state = dest.get("state", {})
entities = state.get("entities", [])
if not isinstance(entities, list):
    fail("invalid destination snapshot: entities not list")

# prevent duplicates
for ent in entities:
    if isinstance(ent, dict) and ent.get("id") == entity.get("id"):
        fail("entity already exists in destination")

entity = dict(entity)
entity["zone"] = dest_zone

entities.append(entity)
entities.sort(key=lambda e: str(e.get("id")))

new_dest = {
    "world": dest.get("world"),
    "zone": dest.get("zone"),
    "state": {"entities": entities},
    "source_snapshot_hash": dest.get("source_snapshot_hash"),
}

with open(out_dest, "w") as fh:
    fh.write(json.dumps(new_dest, sort_keys=True, separators=(",", ":")))

print(sha256(json.dumps(new_dest, sort_keys=True, separators=(",", ":")).encode("utf-8")).hexdigest())
