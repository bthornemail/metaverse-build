#!/usr/bin/env python3
import json
import sys

def fail(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)

if len(sys.argv) < 3:
    fail("usage: route-event.py <snapshot.json> <event.json>")

snap_path = sys.argv[1]
event_path = sys.argv[2]

with open(snap_path, "r") as fh:
    snap = json.load(fh)

with open(event_path, "r") as fh:
    ev = json.load(fh)

state = snap.get("state", {})
entities = state.get("entities", [])
if not isinstance(entities, list):
    fail("invalid snapshot: entities not list")

# Determine target entity id based on event type
etype = ev.get("type")
if etype == "ENTITY_CREATE":
    eid = ev.get("id")
else:
    eid = ev.get("entity") or ev.get("id")

if not isinstance(eid, str):
    fail("event missing target entity id")

zone = None
for ent in entities:
    if isinstance(ent, dict) and ent.get("id") == eid:
        zone = ent.get("zone")
        break

if not zone:
    zone = "zone-unknown"

print(zone)
