#!/usr/bin/env python3
import json
import os
import sys
from hashlib import sha256


def fail(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)

if len(sys.argv) < 2:
    fail("usage: restore.py <bundle_dir>")

bundle_dir = sys.argv[1]
manifest_path = os.path.join(bundle_dir, "manifest.json")
if not os.path.exists(manifest_path):
    fail("manifest.json not found")

manifest = json.load(open(manifest_path, "r"))

snap_path = os.path.join(bundle_dir, manifest.get("snapshot", ""))
trace_path = os.path.join(bundle_dir, manifest.get("trace", ""))
ck_path = os.path.join(bundle_dir, manifest.get("checkpoint", ""))

for p in (snap_path, trace_path, ck_path):
    if not os.path.exists(p):
        fail(f"missing bundle file: {p}")

snap_hash = sha256(open(snap_path, "rb").read()).hexdigest()
trace_hash = sha256(open(trace_path, "rb").read()).hexdigest()
ck_hash = sha256(open(ck_path, "rb").read()).hexdigest()

if snap_hash != manifest.get("snapshot_hash"):
    print("HALT: snapshot hash mismatch", file=sys.stderr)
    sys.exit(3)
if trace_hash != manifest.get("trace_hash"):
    print("HALT: trace hash mismatch", file=sys.stderr)
    sys.exit(3)
if ck_hash != manifest.get("checkpoint_hash"):
    print("HALT: checkpoint hash mismatch", file=sys.stderr)
    sys.exit(3)

print("OK")
