#!/usr/bin/env python3
import json
import sys
import os
from hashlib import sha256
import subprocess

def fail(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)

if len(sys.argv) < 5:
    fail("usage: window-replay.py <base_snapshot.json> <trace.jsonl> <start_index> <end_index> <out_snapshot>")

base_snapshot = sys.argv[1]
trace_path = sys.argv[2]
start = int(sys.argv[3])
end = int(sys.argv[4])
out_snapshot = sys.argv[5] if len(sys.argv) > 5 else ""

lines = [line for line in open(trace_path, "r") if line.strip()]
if start < 0 or end < start or end >= len(lines):
    fail("invalid window indices")

import tempfile
with tempfile.NamedTemporaryFile(mode="w", delete=False) as tmp:
    for line in lines[start:end+1]:
        tmp.write(line)
    tmp_path = tmp.name

script_dir = os.path.dirname(os.path.abspath(__file__))
apply_path = os.path.join(script_dir, "..", "world", "apply-event.py")
proc = subprocess.run([sys.executable, apply_path, base_snapshot, tmp_path, out_snapshot], capture_output=True, text=True)
if proc.returncode != 0:
    sys.stderr.write(proc.stderr)
    sys.exit(proc.returncode)

with open(out_snapshot, "rb") as fh:
    snap_hash = sha256(fh.read()).hexdigest()

print(snap_hash)
