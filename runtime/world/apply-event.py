#!/usr/bin/env python3
import json
import sys
from hashlib import sha256

def fail(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)

if len(sys.argv) < 3:
    fail("usage: apply-event.py <snapshot.json> <events.jsonl> [out_snapshot]")

snap_path = sys.argv[1]
events_path = sys.argv[2]
out_path = sys.argv[3] if len(sys.argv) > 3 else ""

with open(snap_path, "r") as fh:
    snap = json.load(fh)

state = snap.get("state")
if not isinstance(state, dict):
    fail("invalid snapshot: missing state")

entities = state.get("entities", [])
if not isinstance(entities, list):
    fail("invalid snapshot: entities not list")

# Index entities by id
ent_index = {e.get("id"): e for e in entities}

# deterministic internal id assignment
existing_internal = [e.get("internal", "") for e in entities if isinstance(e, dict)]
_next_internal_num = 1
for internal in existing_internal:
    if internal and internal.startswith("e") and internal[1:].isdigit():
        _next_internal_num = max(_next_internal_num, int(internal[1:]) + 1)


def get_or_create_entity(eid, internal=None):
    global _next_internal_num
    if eid in ent_index:
        return ent_index[eid]
    if internal is None:
        internal = f"e{_next_internal_num}"
        _next_internal_num += 1
    ent = {"id": eid, "internal": internal, "owner": None, "zone": None, "components": []}
    entities.append(ent)
    ent_index[eid] = ent
    return ent

for line in open(events_path, "r"):
    line = line.strip()
    if not line:
        continue
    ev = json.loads(line)
    et = ev.get("type")

    if et == "ENTITY_CREATE":
        eid = ev.get("id")
        if not isinstance(eid, str):
            fail("ENTITY_CREATE requires id")
        internal = ev.get("internal")
        get_or_create_entity(eid, internal)

    elif et == "ENTITY_DESTROY":
        eid = ev.get("id")
        if eid in ent_index:
            ent = ent_index.pop(eid)
            entities.remove(ent)

    elif et == "COMPONENT_ATTACH":
        eid = ev.get("entity")
        ctype = ev.get("component")
        if not isinstance(eid, str) or not isinstance(ctype, str):
            fail("COMPONENT_ATTACH requires entity and component")
        ent = get_or_create_entity(eid)
        comps = ent.get("components", [])
        cid = ev.get("cid")
        if not cid:
            cid = f"{ent['internal']}.c{len(comps)+1}"
        data = ev.get("data", {})
        comps.append({"id": cid, "type": ctype, "data": data})
        ent["components"] = comps

    elif et == "COMPONENT_UPDATE":
        eid = ev.get("entity")
        ctype = ev.get("component")
        patch = ev.get("patch", {})
        if not isinstance(eid, str) or not isinstance(ctype, str):
            fail("COMPONENT_UPDATE requires entity and component")
        ent = ent_index.get(eid)
        if not ent:
            fail("COMPONENT_UPDATE on missing entity")
        for comp in ent.get("components", []):
            if comp.get("type") == ctype:
                data = comp.get("data", {})
                if not isinstance(data, dict):
                    data = {}
                if isinstance(patch, dict):
                    data.update(patch)
                comp["data"] = data
                break

    elif et == "COMPONENT_DETACH":
        eid = ev.get("entity")
        ctype = ev.get("component")
        if not isinstance(eid, str) or not isinstance(ctype, str):
            fail("COMPONENT_DETACH requires entity and component")
        ent = ent_index.get(eid)
        if not ent:
            continue
        comps = ent.get("components", [])
        for i, comp in enumerate(comps):
            if comp.get("type") == ctype:
                comps.pop(i)
                break
        ent["components"] = comps

    elif et == "ZONE_MOVE":
        eid = ev.get("entity")
        zone = ev.get("zone")
        if not isinstance(eid, str) or not isinstance(zone, str):
            fail("ZONE_MOVE requires entity and zone")
        ent = get_or_create_entity(eid)
        ent["zone"] = zone

    else:
        fail(f"unknown event type: {et}")

new_snap = {
    "world": snap.get("world"),
    "state": state,
    "trace_seed": snap.get("trace_seed", []),
}

snap_bytes = json.dumps(new_snap, sort_keys=True, separators=(",", ":")).encode("utf-8")
if out_path:
    with open(out_path, "w") as fh:
        fh.write(snap_bytes.decode("utf-8"))

print(sha256(snap_bytes).hexdigest())
