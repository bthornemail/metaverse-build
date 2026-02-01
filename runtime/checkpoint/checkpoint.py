#!/usr/bin/env python3
import json
import sys
from hashlib import sha256
from datetime import datetime, timezone


def fail(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)

if len(sys.argv) < 6:
    fail("usage: checkpoint.py <zone> <base_snapshot.json> <trace.jsonl> <out_snapshot> <out_checkpoint>")

zone = sys.argv[1]
base_path = sys.argv[2]
trace_path = sys.argv[3]
out_snapshot = sys.argv[4]
out_checkpoint = sys.argv[5]

with open(base_path, "r") as fh:
    snap = json.load(fh)

state = snap.get("state")
if not isinstance(state, dict):
    fail("invalid snapshot: missing state")

# Apply events using existing interpreter logic by importing apply-event via subprocess
# to preserve identical semantics.
import os
import subprocess

# Use apply-event.py to compute snapshot deterministically
script_dir = os.path.dirname(os.path.abspath(__file__))
apply_path = os.path.join(script_dir, "..", "world", "apply-event.py")
apply_cmd = [sys.executable, apply_path, base_path, trace_path, out_snapshot]

proc = subprocess.run(apply_cmd, capture_output=True, text=True)
if proc.returncode != 0:
    sys.stderr.write(proc.stderr)
    sys.exit(proc.returncode)

# Compute snapshot hash
with open(out_snapshot, "rb") as fh:
    snap_bytes = fh.read()

snap_hash = sha256(snap_bytes).hexdigest()

checkpoint = {
    "zone": zone,
    "trace": trace_path,
    "snapshot": out_snapshot,
    "last_index": sum(1 for line in open(trace_path, "r") if line.strip()) - 1,
    "snapshot_hash": snap_hash,
    "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
}

if out_checkpoint:
    with open(out_checkpoint, "w") as fh:
        fh.write(json.dumps(checkpoint, sort_keys=True, separators=(",", ":")))

print(snap_hash)
