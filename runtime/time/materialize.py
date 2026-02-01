#!/usr/bin/env python3
import json
import os
import sys
import subprocess


def fail(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)

if len(sys.argv) < 6:
    fail("usage: materialize.py <checkpoint.json> <trace.jsonl> <start_index> <end_index> <out_snapshot>")

ck_path = sys.argv[1]
trace_path = sys.argv[2]
start = int(sys.argv[3])
end = int(sys.argv[4])
out_snapshot = sys.argv[5]

ck = json.load(open(ck_path, "r"))
base_snapshot = ck.get("snapshot")
if not base_snapshot:
    fail("checkpoint missing snapshot")

script_dir = os.path.dirname(os.path.abspath(__file__))
window_path = os.path.join(script_dir, "..", "checkpoint", "window-replay.py")

proc = subprocess.run([sys.executable, window_path, base_snapshot, trace_path, str(start), str(end), out_snapshot], capture_output=True, text=True)
if proc.returncode != 0:
    sys.stderr.write(proc.stderr)
    sys.exit(proc.returncode)

print(proc.stdout.strip())
