#!/usr/bin/env python3
import json
import os
from datetime import datetime, timezone

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT_DIR = os.path.join(ROOT, "projections", "mind-git", "reports")
os.makedirs(OUT_DIR, exist_ok=True)

peergraph_path = os.path.join(ROOT, "runtime", "lattice", "graph", "peergraph.json")
basis_path = os.path.join(ROOT, "runtime", "lattice", "graph", "basis.json")
routing_log = os.path.join(ROOT, "runtime", "lattice", "trace", "routing.log")

def load_json(path):
    if not os.path.exists(path):
        return {}
    with open(path, "r") as fh:
        return json.load(fh)

peergraph = load_json(peergraph_path)
basis = load_json(basis_path)

last_events = []
if os.path.exists(routing_log):
    with open(routing_log, "r") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                last_events.append(json.loads(line))
            except Exception:
                continue
last_events = last_events[-2:]

selected = basis.get("selected", [])
sel_peer = selected[0].get("peer") if selected else "unknown"
sel_score = selected[0].get("score") if selected else 0

peer_rtt = {}
for n in peergraph.get("nodes", []):
    peer_rtt[n.get("id", "unknown")] = n.get("health", {}).get("rtt_ms", 0)

out_path = os.path.join(OUT_DIR, "basis-flip.md")
with open(out_path, "w") as fh:
    fh.write("# Basis Selection Report\n\n")
    fh.write(f"Generated: {datetime.now(timezone.utc).isoformat()}\n\n")
    fh.write("## Current Selection\n\n")
    fh.write(f"- Selected peer: `{sel_peer}`\n")
    fh.write(f"- Score: `{sel_score}`\n")
    fh.write(f"- RTT: `{peer_rtt.get(sel_peer, 0)} ms`\n\n")
    fh.write("## Recent Routing Events\n\n")
    if not last_events:
        fh.write("_No routing events available._\n")
    else:
        for ev in last_events:
            fh.write(f"- `{ev.get('type','unknown')}` at {ev.get('t','?')}\n")
    fh.write("\n## Notes\n\n")
    fh.write("This report is a projection derived from trace and plan artifacts. ")
    fh.write("It is non-authoritative and reproducible.\n")

print(out_path)
