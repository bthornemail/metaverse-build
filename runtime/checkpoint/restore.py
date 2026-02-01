#!/usr/bin/env python3
import json
import os
import sys
from hashlib import sha256
import subprocess


def fail(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)

if len(sys.argv) < 3:
    fail("usage: restore.py <checkpoint.json> <out_snapshot>")

ck_path = sys.argv[1]
out_snapshot = sys.argv[2]

with open(ck_path, "r") as fh:
    ck = json.load(fh)

trace_path = ck.get("trace")
base_snapshot = ck.get("snapshot")
last_index = ck.get("last_index")
expected_hash = ck.get("snapshot_hash")

if not trace_path or not base_snapshot or expected_hash is None:
    fail("invalid checkpoint: missing fields")

# Verify base snapshot hash
with open(base_snapshot, "rb") as fh:
    base_hash = sha256(fh.read()).hexdigest()

if base_hash != expected_hash:
    print("HALT: corruption", file=sys.stderr)
    sys.exit(3)

# Replay events after last_index into output snapshot
script_dir = os.path.dirname(os.path.abspath(__file__))
apply_path = os.path.join(script_dir, "..", "world", "apply-event.py")

# Extract tail of trace
lines = [line for line in open(trace_path, "r") if line.strip()]
start = (last_index + 1) if isinstance(last_index, int) else len(lines)

if start >= len(lines):
    # nothing to replay; copy snapshot
    with open(base_snapshot, "rb") as src, open(out_snapshot, "wb") as dst:
        dst.write(src.read())
    print(expected_hash)
    sys.exit(0)

import tempfile
with tempfile.NamedTemporaryFile(mode="w", delete=False) as tmp:
    for line in lines[start:]:
        tmp.write(line)
    tmp_path = tmp.name

proc = subprocess.run([sys.executable, apply_path, base_snapshot, tmp_path, out_snapshot], capture_output=True, text=True)
if proc.returncode != 0:
    sys.stderr.write(proc.stderr)
    sys.exit(proc.returncode)

with open(out_snapshot, "rb") as fh:
    new_hash = sha256(fh.read()).hexdigest()

print(new_hash)
