#!/usr/bin/env python3
import json
import os
import sys

def fail(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)

if len(sys.argv) < 2:
    fail("usage: intent-to-event.py <command> [args...] --actor <id> [--owner <id>] [--data <json>] [--patch <json>]")

args = sys.argv[1:]

def take_flag(flag):
    if flag in args:
        idx = args.index(flag)
        if idx + 1 >= len(args):
            fail(f"{flag} requires value")
        val = args[idx + 1]
        del args[idx:idx + 2]
        return val
    return None

actor = take_flag("--actor") or os.environ.get("ACTOR")
if not actor:
    fail("actor required (set ACTOR or --actor)")

owner = take_flag("--owner")

data_json = take_flag("--data")
patch_json = take_flag("--patch")

cmd = args[0]
cmd_args = args[1:]

ev = {"type": None}

if cmd == "create":
    if len(cmd_args) < 1:
        fail("create requires id")
    eid = cmd_args[0]
    if not owner:
        owner = actor
    ev = {"type": "ENTITY_CREATE", "id": eid, "owner": owner, "actor": actor}
elif cmd == "destroy":
    if len(cmd_args) < 1:
        fail("destroy requires id")
    eid = cmd_args[0]
    ev = {"type": "ENTITY_DESTROY", "id": eid, "actor": actor}
elif cmd == "attach":
    if len(cmd_args) < 2:
        fail("attach requires id and component")
    eid = cmd_args[0]
    comp = cmd_args[1]
    data = {}
    if data_json:
        data = json.loads(data_json)
    ev = {"type": "COMPONENT_ATTACH", "entity": eid, "component": comp, "data": data, "actor": actor}
elif cmd == "update":
    if len(cmd_args) < 2:
        fail("update requires id and component")
    eid = cmd_args[0]
    comp = cmd_args[1]
    patch = {}
    if patch_json:
        patch = json.loads(patch_json)
    ev = {"type": "COMPONENT_UPDATE", "entity": eid, "component": comp, "patch": patch, "actor": actor}
elif cmd == "detach":
    if len(cmd_args) < 2:
        fail("detach requires id and component")
    eid = cmd_args[0]
    comp = cmd_args[1]
    ev = {"type": "COMPONENT_DETACH", "entity": eid, "component": comp, "actor": actor}
elif cmd == "move":
    if len(cmd_args) < 2:
        fail("move requires id and zone")
    eid = cmd_args[0]
    zone = cmd_args[1]
    ev = {"type": "ZONE_MOVE", "entity": eid, "zone": zone, "actor": actor}
else:
    fail(f"unknown command: {cmd}")

print(json.dumps(ev, separators=(",", ":")))
