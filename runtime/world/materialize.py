#!/usr/bin/env python3
import json
import os
import sys
from hashlib import sha256

def fail(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)

if len(sys.argv) < 2:
    fail("usage: materialize.py <world.ir.json> [out_snapshot] [out_trace]")

ir_path = sys.argv[1]
if not os.path.exists(ir_path):
    fail(f"input not found: {ir_path}")

with open(ir_path, "r") as fh:
    ir = json.load(fh)

if not isinstance(ir, dict) or "world" not in ir:
    fail("invalid IR: missing world")

world_name = ir["world"]
entities = ir.get("entities", []) or []

state = {
    "world": world_name,
    "entities": [],
    "zones": ir.get("zones", []) or [],
}

trace = []
trace.append({"type": "WORLD_LOAD", "world": world_name, "zones": ir.get("zones", []) or []})

# Deterministic materialization: preserve list order
for ei, ent in enumerate(entities, start=1):
    eid = ent.get("id")
    if not isinstance(eid, str):
        fail("invalid entity id")
    internal_id = f"e{ei}"
    comp_list = []
    trace.append({"type": "ENTITY_CREATE", "id": eid, "internal": internal_id})
    comps = ent.get("components", []) or []
    for ci, comp in enumerate(comps, start=1):
        ctype = comp.get("type")
        if not isinstance(ctype, str):
            fail("invalid component type")
        cid = f"{internal_id}.c{ci}"
        cdata = comp.get("data", {})
        comp_list.append({"id": cid, "type": ctype, "data": cdata})
        trace.append({"type": "COMPONENT_ATTACH", "entity": eid, "component": ctype, "cid": cid, "data": cdata})

    state["entities"].append({
        "id": eid,
        "internal": internal_id,
        "owner": ent.get("owner"),
        "zone": ent.get("zone"),
        "components": comp_list,
    })

    if ent.get("owner") is not None:
        trace.append({"type": "ENTITY_OWNER", "entity": eid, "owner": ent.get("owner")})
    if ent.get("zone") is not None:
        trace.append({"type": "ENTITY_ZONE", "entity": eid, "zone": ent.get("zone")})

snapshot = {
    "world": world_name,
    "state": state,
    "trace_seed": trace,
}

# Stable content hash
snapshot_bytes = json.dumps(snapshot, sort_keys=True, separators=(",", ":")).encode("utf-8")
shash = sha256(snapshot_bytes).hexdigest()

out_snapshot = sys.argv[2] if len(sys.argv) > 2 else ""
out_trace = sys.argv[3] if len(sys.argv) > 3 else ""

if out_snapshot:
    with open(out_snapshot, "w") as fh:
        fh.write(snapshot_bytes.decode("utf-8"))

if out_trace:
    with open(out_trace, "w") as fh:
        for ev in trace:
            fh.write(json.dumps(ev, separators=(",", ":")) + "\n")

print(shash)
