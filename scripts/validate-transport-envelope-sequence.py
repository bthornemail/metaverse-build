#!/usr/bin/env python3
import json
import os
import sys


def fail(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)


def require_obj(x, label):
    if not isinstance(x, dict):
        fail(f"{label} must be object")


def main():
    if len(sys.argv) != 2:
        fail("usage: validate-transport-envelope-sequence.py <envelopes.ndjson>")

    p = sys.argv[1]
    if not os.path.exists(p):
        fail(f"input not found: {p}")

    last_seq = {}
    seen = set()
    with open(p, "r") as fh:
        for ln, raw in enumerate(fh, start=1):
            line = raw.strip()
            if not line:
                continue
            try:
                env = json.loads(line)
            except json.JSONDecodeError:
                fail(f"line {ln}: invalid json")
            require_obj(env, f"line {ln}")
            keys = sorted(env.keys())
            if keys != ["event", "peer", "seq"]:
                fail(f"line {ln}: envelope keyset mismatch")
            peer = env.get("peer")
            seq = env.get("seq")
            event = env.get("event")
            if not isinstance(peer, str) or not peer:
                fail(f"line {ln}: peer invalid")
            if not isinstance(seq, int) or seq < 1:
                fail(f"line {ln}: seq invalid")
            require_obj(event, f"line {ln}.event")
            dedupe_key = (peer, seq)
            if dedupe_key in seen:
                fail(f"line {ln}: duplicate peer/seq")
            seen.add(dedupe_key)
            prev = last_seq.get(peer, 0)
            if seq != prev + 1:
                fail(f"line {ln}: non-contiguous seq for peer={peer}")
            last_seq[peer] = seq

    print("ok transport envelope sequence")


if __name__ == "__main__":
    main()
