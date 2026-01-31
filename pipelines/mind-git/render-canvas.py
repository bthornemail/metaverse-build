#!/usr/bin/env python3
import json
import os
import uuid

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT_DIR = os.path.join(ROOT, "projections", "mind-git", "canvas")
os.makedirs(OUT_DIR, exist_ok=True)

peergraph_path = os.path.join(ROOT, "runtime", "lattice", "graph", "peergraph.json")
basis_path = os.path.join(ROOT, "runtime", "lattice", "graph", "basis.json")
plan_path = os.path.join(ROOT, "runtime", "lattice", "plan", "connection-plan.json")

def load_json(path):
    if not os.path.exists(path):
        return {}
    with open(path, "r") as fh:
        return json.load(fh)

peergraph = load_json(peergraph_path)
basis = load_json(basis_path)
plan = load_json(plan_path)

nodes = []
edges = []

def nid():
    return uuid.uuid4().hex

def text_node(text, x, y, w=240, h=80):
    node_id = nid()
    nodes.append({
        "id": node_id,
        "type": "text",
        "x": x,
        "y": y,
        "width": w,
        "height": h,
        "text": text,
    })
    return node_id

status_id = text_node("Status: Projection only. Non-authoritative.", 40, 40, 360, 60)
peer_ids = {}

y = 140
for n in peergraph.get("nodes", []):
    peer = n.get("id", "unknown")
    rtt = n.get("health", {}).get("rtt_ms", 0)
    port = n.get("ports", {}).get("bus", 0)
    label = f"Peer: {peer}\\nRTT: {rtt}ms\\nBus: {port}"
    peer_ids[peer] = text_node(label, 40, y, 260, 90)
    y += 110

basis_id = text_node("Basis Selection", 360, 140, 240, 80)
for sel in basis.get("selected", []):
    peer = sel.get("peer", "unknown")
    score = sel.get("score", 0)
    label_id = text_node(f"Selected: {peer}\\nScore: {score}", 360, 240 + 100 * len(edges), 240, 80)
    if peer in peer_ids:
        edges.append({
            "id": nid(),
            "fromNode": peer_ids[peer],
            "toNode": label_id,
            "label": "selected",
        })

plan_id = text_node("Connection Plan", 680, 140, 260, 80)
attachments = plan.get("attachments", [])
py = 240
for att in attachments:
    peer = att.get("peer", "unknown")
    tcp = att.get("trace_tcp", "")
    label_id = text_node(f"Plan: {peer}\\n{tcp}", 680, py, 260, 80)
    py += 100
    edges.append({
        "id": nid(),
        "fromNode": basis_id,
        "toNode": label_id,
        "label": "projects-to",
    })

canvas = {"nodes": nodes, "edges": edges}

out_path = os.path.join(OUT_DIR, "PeerGraph.canvas")
with open(out_path, "w") as fh:
    json.dump(canvas, fh, separators=(",", ":"))

print(out_path)
