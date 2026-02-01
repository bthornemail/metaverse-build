#!/usr/bin/env python3
import re
import sys

def fail(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)

if len(sys.argv) < 2:
    fail("usage: interest.py <zone> [radius]")

zone = sys.argv[1]
radius = int(sys.argv[2]) if len(sys.argv) > 2 else 1

m = re.match(r"^tile-(-?\d+)-(-?\d+)$", zone)
if not m:
    print(zone)
    sys.exit(0)

x = int(m.group(1))
y = int(m.group(2))

zones = []
for dx in range(-radius, radius + 1):
    for dy in range(-radius, radius + 1):
        zones.append((x + dx, y + dy))

zones.sort()
for zx, zy in zones:
    print(f"tile-{zx}-{zy}")
