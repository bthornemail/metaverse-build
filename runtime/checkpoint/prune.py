#!/usr/bin/env python3
import os
import sys
import json

def fail(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)

if len(sys.argv) < 3:
    fail("usage: prune.py <checkpoint_dir> <keep_n>")

ck_dir = sys.argv[1]
keep_n = int(sys.argv[2])

if not os.path.isdir(ck_dir):
    fail("checkpoint_dir not found")

ck_files = [f for f in os.listdir(ck_dir) if f.endswith(".checkpoint.json")]

def ck_key(name):
    path = os.path.join(ck_dir, name)
    try:
        with open(path, "r") as fh:
            data = json.load(fh)
        return data.get("timestamp", ""), name
    except Exception:
        return "", name

ck_files.sort(key=ck_key)

remove = ck_files[:-keep_n] if keep_n < len(ck_files) else []

for ck in remove:
    ck_path = os.path.join(ck_dir, ck)
    with open(ck_path, "r") as fh:
        data = json.load(fh)
    snap_path = data.get("snapshot")
    if snap_path and os.path.exists(snap_path):
        os.remove(snap_path)
    os.remove(ck_path)

print("removed", len(remove))
