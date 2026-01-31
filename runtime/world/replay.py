#!/usr/bin/env python3
import json
import sys
from hashlib import sha256

def fail(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)

if len(sys.argv) < 2:
    fail("usage: replay.py <seed.trace.jsonl> [out_snapshot]")

trace_path = sys.argv[1]
state_out = sys.argv[2] if len(sys.argv) > 2 else ""

state = {
    "world": None,
    "entities": [],
    "zones": [],
}

# deterministic internal id map
internal_ids = {}
components = {}

with open(trace_path, "r") as fh:
    for line in fh:
        line = line.strip()
        if not line:
            continue
        ev = json.loads(line)
        et = ev.get("type")
        if et == "WORLD_LOAD":
            state["world"] = ev.get("world")
            zones = ev.get("zones", [])
            state["zones"] = zones if isinstance(zones, list) else []
        elif et == "ENTITY_CREATE":
            eid = ev.get("id")
            internal = ev.get("internal")
            internal_ids[eid] = internal
            components[eid] = []
            state["entities"].append({
                "id": eid,
                "internal": internal,
                "owner": None,
                "zone": None,
                "components": components[eid],
            })
        elif et == "COMPONENT_ATTACH":
            eid = ev.get("entity")
            ctype = ev.get("component")
            cid = ev.get("cid")
            cdata = ev.get("data", {})
            if eid not in components:
                fail("component attach for unknown entity")
            components[eid].append({
                "id": cid,
                "type": ctype,
                "data": cdata,
            })
        elif et == "ENTITY_OWNER":
            eid = ev.get("entity")
            owner = ev.get("owner")
            for ent in state["entities"]:
                if ent["id"] == eid:
                    ent["owner"] = owner
                    break
        elif et == "ENTITY_ZONE":
            eid = ev.get("entity")
            zone = ev.get("zone")
            for ent in state["entities"]:
                if ent["id"] == eid:
                    ent["zone"] = zone
                    break
        else:
            fail(f"unknown event type: {et}")

with open(trace_path, "r") as fh:
    trace_seed = [json.loads(line) for line in fh if line.strip()]

snapshot = {
    "world": state["world"],
    "state": state,
    "trace_seed": trace_seed,
}

snap_bytes = json.dumps(snapshot, sort_keys=True, separators=(",", ":")).encode("utf-8")
if state_out:
    with open(state_out, "w") as fh:
        fh.write(snap_bytes.decode("utf-8"))
print(sha256(snap_bytes).hexdigest())
