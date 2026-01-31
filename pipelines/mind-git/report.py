#!/usr/bin/env python3
import json
import os
import hashlib
from datetime import datetime, timezone

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT_DIR = os.path.join(ROOT, "projections", "mind-git", "reports")
os.makedirs(OUT_DIR, exist_ok=True)

peergraph_path = os.path.join(ROOT, "runtime", "lattice", "graph", "peergraph.json")
basis_path = os.path.join(ROOT, "runtime", "lattice", "graph", "basis.json")
routing_log = os.path.join(ROOT, "runtime", "lattice", "trace", "routing.log")
plan_history_dir = os.path.join(ROOT, "projections", "mind-git", "plan-history")

def load_json(path):
    if not os.path.exists(path):
        return {}
    with open(path, "r") as fh:
        return json.load(fh)

def parse_jsonl(path):
    events = []
    if not os.path.exists(path):
        return events
    with open(path, "r") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                events.append(json.loads(line))
            except Exception:
                continue
    return events

peergraph = load_json(peergraph_path)
basis = load_json(basis_path)

def sha256_file(path):
    with open(path, "rb") as fh:
        return hashlib.sha256(fh.read()).hexdigest()

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

plan_peers = {}
if os.path.isdir(plan_history_dir):
    for fname in os.listdir(plan_history_dir):
        if not fname.endswith(".json"):
            continue
        path = os.path.join(plan_history_dir, fname)
        try:
            plan = load_json(path)
        except Exception:
            continue
        attachments = plan.get("attachments", [])
        first = attachments[0] if attachments else {}
        plan_peers[fname.replace(".json","")] = first.get("peer", "unknown")

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

    # Flip sections with plan hash links
    all_events = parse_jsonl(routing_log)
    flips = [ev for ev in all_events if ev.get("type") == "rebind"]
    if flips:
        fh.write("\n## Basis Flips\n\n")
    prev_hash = None
    for ev in flips:
        plan_path = ev.get("plan", "")
        if plan_path and os.path.exists(plan_path):
            cur_hash = sha256_file(plan_path)
        else:
            cur_hash = "unknown"
        if prev_hash is not None and cur_hash == prev_hash:
            continue
        fh.write(f"### Basis Flip @ {ev.get('t','?')}\n")
        if prev_hash and cur_hash != "unknown":
            fh.write(f"- Plan: `{prev_hash[:8]}` → `{cur_hash[:8]}`\n")
            fh.write(f"- Links: #{prev_hash[:8]}, #{cur_hash[:8]}\n")
        elif cur_hash != "unknown":
            fh.write(f"- Plan: `{cur_hash[:8]}`\n")
            fh.write(f"- Link: #{cur_hash[:8]}\n")
        if prev_hash and prev_hash in plan_peers and cur_hash in plan_peers:
            fh.write(f"- Selected peer: {plan_peers.get(prev_hash,'unknown')} → {plan_peers.get(cur_hash,'unknown')}\n")
        elif cur_hash in plan_peers:
            fh.write(f"- Selected peer: {plan_peers.get(cur_hash,'unknown')}\n")
        cur_peer = plan_peers.get(cur_hash, sel_peer)
        fh.write(f"- Evidence: RTT({cur_peer}) = {peer_rtt.get(cur_peer, 0)} ms\n\n")
        prev_hash = cur_hash
    fh.write("\n## Notes\n\n")
    fh.write("This report is a projection derived from trace and plan artifacts. ")
    fh.write("It is non-authoritative and reproducible.\n")

print(out_path)
