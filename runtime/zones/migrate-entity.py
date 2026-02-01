#!/usr/bin/env python3
import json
import sys
from hashlib import sha256

def fail(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)

if len(sys.argv) < 5:
    fail("usage: migrate-entity.py <source_zone_snapshot> <entity_id> <dest_zone> <out_transfer> [out_source_snapshot]")

src_path = sys.argv[1]
entity_id = sys.argv[2]
dest_zone = sys.argv[3]
transfer_path = sys.argv[4]
out_source = sys.argv[5] if len(sys.argv) > 5 else ""

with open(src_path, "r") as fh:
    src = json.load(fh)

state = src.get("state", {})
entities = state.get("entities", [])
if not isinstance(entities, list):
    fail("invalid source snapshot: entities not list")

src_zone = src.get("zone")
if not isinstance(src_zone, str) or not src_zone:
    fail("invalid source snapshot: missing zone")

found = None
remaining = []
for ent in entities:
    if isinstance(ent, dict) and ent.get("id") == entity_id:
        found = ent
    else:
        remaining.append(ent)

if not found:
    fail("entity not found in source zone")

transfer = {
    "entity": found,
    "from": src_zone,
    "to": dest_zone,
    "source_snapshot_hash": src.get("source_snapshot_hash"),
}

with open(transfer_path, "w") as fh:
    fh.write(json.dumps(transfer, sort_keys=True, separators=(",", ":")))

if out_source:
    new_src = {
        "world": src.get("world"),
        "zone": src_zone,
        "state": {"entities": remaining},
        "source_snapshot_hash": src.get("source_snapshot_hash"),
    }
    with open(out_source, "w") as fh:
        fh.write(json.dumps(new_src, sort_keys=True, separators=(",", ":")))

print(sha256(json.dumps(transfer, sort_keys=True, separators=(",", ":")).encode("utf-8")).hexdigest())
