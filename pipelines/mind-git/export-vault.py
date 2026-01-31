#!/usr/bin/env python3
import json
import os
import shutil
from datetime import datetime, timezone

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
VAULT = os.path.abspath(os.path.join(ROOT, "..", "dev-vault", "metaverse"))

PROJ = os.path.join(ROOT, "projections", "mind-git")
PLAN_STORE = os.path.join(PROJ, "plan-history")
REPORTS = os.path.join(PROJ, "reports")
CANVAS = os.path.join(PROJ, "canvas")

def ensure_dir(path):
    os.makedirs(path, exist_ok=True)

def read_json(path):
    with open(path, "r") as fh:
        return json.load(fh)

def flatten(obj, prefix=""):
    items = {}
    if isinstance(obj, dict):
        for k in sorted(obj.keys()):
            v = obj[k]
            key = f"{prefix}.{k}" if prefix else k
            items.update(flatten(v, key))
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            key = f"{prefix}[{i}]"
            items.update(flatten(v, key))
    else:
        items[prefix] = obj
    return items

def structural_diff(prev_obj, curr_obj):
    prev_flat = flatten(prev_obj)
    curr_flat = flatten(curr_obj)
    added = []
    removed = []
    changed = []
    for k in sorted(curr_flat.keys()):
        if k not in prev_flat:
            added.append((k, curr_flat[k]))
        elif prev_flat[k] != curr_flat[k]:
            changed.append((k, prev_flat[k], curr_flat[k]))
    for k in sorted(prev_flat.keys()):
        if k not in curr_flat:
            removed.append((k, prev_flat[k]))
    return added, removed, changed

def write_basis_canvas(out_path):
    basis_path = os.path.join(ROOT, "runtime", "lattice", "graph", "basis.json")
    basis = read_json(basis_path) if os.path.exists(basis_path) else {}
    selected = basis.get("selected", [])
    peer = selected[0].get("peer", "unknown") if selected else "unknown"
    score = selected[0].get("score", 0) if selected else 0
    canvas = {
        "nodes": [
            {
                "id": "basis-text",
                "type": "text",
                "x": 40,
                "y": 40,
                "width": 260,
                "height": 100,
                "text": f"Basis Selection\\nPeer: {peer}\\nScore: {score}",
            }
        ],
        "edges": [],
    }
    with open(out_path, "w") as fh:
        json.dump(canvas, fh, separators=(",", ":"))

def read_index():
    index_path = os.path.join(PLAN_STORE, "index.jsonl")
    entries = []
    if not os.path.exists(index_path):
        return entries
    with open(index_path, "r") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                entries.append(json.loads(line))
            except Exception:
                continue
    entries.sort(key=lambda e: (e.get("t", 0), e.get("hash", "")))
    # de-duplicate consecutive identical hashes
    deduped = []
    last = None
    for e in entries:
        h = e.get("hash")
        if h == last:
            continue
        deduped.append(e)
        last = h
    return deduped

def export():
    plans_dir = os.path.join(VAULT, "plans")
    diffs_dir = os.path.join(plans_dir, "diffs")
    graphs_dir = os.path.join(VAULT, "graphs")
    reports_dir = os.path.join(VAULT, "reports")

    ensure_dir(plans_dir)
    ensure_dir(diffs_dir)
    ensure_dir(graphs_dir)
    ensure_dir(reports_dir)

    # plan history + latest
    plan_history_src = os.path.join(REPORTS, "plan-history.md")
    if os.path.exists(plan_history_src):
        shutil.copyfile(plan_history_src, os.path.join(plans_dir, "plan-history.md"))

    latest_plan = os.path.join(ROOT, "runtime", "lattice", "plan", "connection-plan.json")
    if os.path.exists(latest_plan):
        shutil.copyfile(latest_plan, os.path.join(plans_dir, "latest-plan.json"))

    # diffs
    entries = read_index()
    for i in range(1, len(entries)):
        prev = entries[i - 1]["hash"]
        curr = entries[i]["hash"]
        prev_path = os.path.join(PLAN_STORE, f"{prev}.json")
        curr_path = os.path.join(PLAN_STORE, f"{curr}.json")
        if not os.path.exists(prev_path) or not os.path.exists(curr_path):
            continue
        prev_obj = read_json(prev_path)
        curr_obj = read_json(curr_path)
        added, removed, changed = structural_diff(prev_obj, curr_obj)
        out_name = f"{prev[:8]}→{curr[:8]}.md"
        out_path = os.path.join(diffs_dir, out_name)
        with open(out_path, "w") as fh:
            fh.write(f"# Diff {prev[:8]} → {curr[:8]}\n\n")
            for k, v in added:
                fh.write(f"+ {k}: {v}\n")
            for k, v in removed:
                fh.write(f"- {k}: {v}\n")
            for k, a, b in changed:
                fh.write(f"~ {k}: {a} → {b}\n")

    # graphs
    peergraph_canvas = os.path.join(CANVAS, "PeerGraph.canvas")
    if os.path.exists(peergraph_canvas):
        shutil.copyfile(peergraph_canvas, os.path.join(graphs_dir, "peergraph.canvas"))
    write_basis_canvas(os.path.join(graphs_dir, "basis.canvas"))

    # reports
    basis_flips = os.path.join(REPORTS, "basis-flip.md")
    if os.path.exists(basis_flips):
        shutil.copyfile(basis_flips, os.path.join(reports_dir, "basis-flips.md"))

    # phase transcripts index
    transcripts = []
    for fname in os.listdir(os.path.join(ROOT, "reports")):
        if fname.endswith(".txt"):
            transcripts.append(fname)
    transcripts.sort()
    out = os.path.join(reports_dir, "phase-transcripts.md")
    with open(out, "w") as fh:
        fh.write("# Phase Transcripts\n\n")
        fh.write(f"Generated: {datetime.now(timezone.utc).isoformat()}\n\n")
        for name in transcripts:
            fh.write(f"- {name}\n")

    # INDEX.md
    index_path = os.path.join(VAULT, "INDEX.md")
    latest_diff = ""
    if os.path.isdir(diffs_dir):
        diffs = [f for f in os.listdir(diffs_dir) if f.endswith(".md")]
        diffs.sort()
        if diffs:
            latest_diff = diffs[-1]

    with open(index_path, "w") as fh:
        fh.write("# Metaverse Runtime Cockpit\n\n")
        fh.write("## Current State\n")
        fh.write("- Latest plan: [[plans/latest-plan.json]]\n")
        fh.write("- Plan history: [[plans/plan-history.md]]\n")
        if latest_diff:
            fh.write(f"- Latest diff: [[plans/diffs/{latest_diff}]]\n")
        fh.write("\n## Graphs\n")
        fh.write("- Peer graph: [[graphs/peergraph.canvas]]\n")
        fh.write("- Basis selection: [[graphs/basis.canvas]]\n")
        fh.write("\n## Reports\n")
        fh.write("- Basis flips: [[reports/basis-flips.md]]\n")
        fh.write("- Phase transcripts: [[reports/phase-transcripts.md]]\n")
        fh.write("\n## How to read this vault\n")
        fh.write("This vault is a projection of lattice runtime artifacts.\n")
        fh.write("All files are regenerated. Nothing here is authoritative.\n")

if __name__ == "__main__":
    export()
    print(VAULT)
