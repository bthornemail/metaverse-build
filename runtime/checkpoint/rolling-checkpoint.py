#!/usr/bin/env python3
import json
import os
import sys
from datetime import datetime, timezone
from hashlib import sha256
import subprocess

def fail(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)

if len(sys.argv) < 6:
    fail("usage: rolling-checkpoint.py <zone> <base_snapshot.json> <trace.jsonl> <out_dir> <checkpoint_id>")

zone = sys.argv[1]
base_path = sys.argv[2]
trace_path = sys.argv[3]
out_dir = sys.argv[4]
ck_id = sys.argv[5]

os.makedirs(out_dir, exist_ok=True)

snap_path = os.path.join(out_dir, f"{ck_id}.snapshot.json")
ck_path = os.path.join(out_dir, f"{ck_id}.checkpoint.json")

script_dir = os.path.dirname(os.path.abspath(__file__))
apply_path = os.path.join(script_dir, "..", "world", "apply-event.py")
proc = subprocess.run([sys.executable, apply_path, base_path, trace_path, snap_path], capture_output=True, text=True)
if proc.returncode != 0:
    sys.stderr.write(proc.stderr)
    sys.exit(proc.returncode)

with open(snap_path, "rb") as fh:
    snap_bytes = fh.read()

snap_hash = sha256(snap_bytes).hexdigest()

last_index = sum(1 for line in open(trace_path, "r") if line.strip()) - 1

ck = {
    "zone": zone,
    "trace": trace_path,
    "snapshot": snap_path,
    "last_index": last_index,
    "snapshot_hash": snap_hash,
    "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
    "checkpoint_id": ck_id,
}

with open(ck_path, "w") as fh:
    fh.write(json.dumps(ck, sort_keys=True, separators=(",", ":")))

print(ck_path)
