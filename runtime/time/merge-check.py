#!/usr/bin/env python3
import json
import sys
from hashlib import sha256


def fail(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)

def deny(msg):
    print(f"HALT: MergeDenied: {msg}", file=sys.stderr)
    sys.exit(3)

if len(sys.argv) < 5:
    fail("usage: merge-check.py <timeline_a.json> <timeline_b.json> <checkpoint_a.json> <checkpoint_b.json>")

path_a = sys.argv[1]
path_b = sys.argv[2]
ck_a = sys.argv[3]
ck_b = sys.argv[4]

tl_a = json.load(open(path_a, "r"))
tl_b = json.load(open(path_b, "r"))

if tl_a.get("world") != tl_b.get("world"):
    deny("world mismatch")

ck_a_data = json.load(open(ck_a, "r"))
ck_b_data = json.load(open(ck_b, "r"))

snap_a = ck_a_data.get("snapshot")
snap_b = ck_b_data.get("snapshot")

if not snap_a or not snap_b:
    fail("checkpoint missing snapshot path")

hash_a = sha256(open(snap_a, "rb").read()).hexdigest()
hash_b = sha256(open(snap_b, "rb").read()).hexdigest()

if hash_a != ck_a_data.get("snapshot_hash"):
    deny("checkpoint A hash mismatch")
if hash_b != ck_b_data.get("snapshot_hash"):
    deny("checkpoint B hash mismatch")

if hash_a != hash_b:
    deny("snapshot hash mismatch")

print("MERGE_OK")
