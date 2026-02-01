#!/usr/bin/env python3
import json
import sys
import uuid


def fail(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)

if len(sys.argv) < 4:
    fail("usage: branch.py <timeline.json> <parent_checkpoint_id> <out_timeline.json>")

timeline_path = sys.argv[1]
parent_id = sys.argv[2]
out_path = sys.argv[3]

with open(timeline_path, "r") as fh:
    tl = json.load(fh)

nodes = tl.get("nodes", {})
if parent_id not in nodes:
    fail("parent checkpoint not found")

new_id = f"branch-{uuid.uuid4().hex[:8]}"

new_tl = {
    "world": tl.get("world"),
    "timeline": new_id,
    "nodes": dict(nodes),
    "root": parent_id,
}

with open(out_path, "w") as fh:
    fh.write(json.dumps(new_tl, sort_keys=True, separators=(",", ":")))

print(new_id)
