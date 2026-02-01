#!/usr/bin/env python3
import json
import os
import sys
from hashlib import sha256


def fail(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)

if len(sys.argv) < 6:
    fail("usage: bundle.py <zone> <snapshot.json> <trace.jsonl> <checkpoint.json> <out_dir>")

zone = sys.argv[1]
snapshot_path = sys.argv[2]
trace_path = sys.argv[3]
checkpoint_path = sys.argv[4]
out_dir = sys.argv[5]

for p in (snapshot_path, trace_path, checkpoint_path):
    if not os.path.exists(p):
        fail(f"missing input: {p}")

os.makedirs(out_dir, exist_ok=True)

bundle_dir = os.path.join(out_dir, zone)
os.makedirs(bundle_dir, exist_ok=True)

snap_bytes = open(snapshot_path, "rb").read()
trace_bytes = open(trace_path, "rb").read()
ck_bytes = open(checkpoint_path, "rb").read()

snap_hash = sha256(snap_bytes).hexdigest()
trace_hash = sha256(trace_bytes).hexdigest()
ck_hash = sha256(ck_bytes).hexdigest()

snap_out = os.path.join(bundle_dir, "zone.snapshot.json")
trace_out = os.path.join(bundle_dir, "zone.trace.jsonl")
ck_out = os.path.join(bundle_dir, "zone.checkpoint.json")

open(snap_out, "wb").write(snap_bytes)
open(trace_out, "wb").write(trace_bytes)
open(ck_out, "wb").write(ck_bytes)

manifest = {
    "zone": zone,
    "snapshot": os.path.basename(snap_out),
    "trace": os.path.basename(trace_out),
    "checkpoint": os.path.basename(ck_out),
    "snapshot_hash": snap_hash,
    "trace_hash": trace_hash,
    "checkpoint_hash": ck_hash,
}

manifest_path = os.path.join(bundle_dir, "manifest.json")
open(manifest_path, "w").write(json.dumps(manifest, sort_keys=True, separators=(",", ":")))

print(manifest_path)
