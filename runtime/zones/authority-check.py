#!/usr/bin/env python3
import json
import sys

def fail(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)

if len(sys.argv) < 4:
    fail("usage: authority-check.py <policy.json> <zone> <actor>")

policy_path = sys.argv[1]
zone = sys.argv[2]
actor = sys.argv[3]

with open(policy_path, "r") as fh:
    policy = json.load(fh)

allowed = set(policy.get(zone, []) or []) | set(policy.get("*", []) or [])

if actor in allowed:
    print("OK")
    sys.exit(0)

print("HALT: ZoneNotAuthorized", file=sys.stderr)
sys.exit(3)
