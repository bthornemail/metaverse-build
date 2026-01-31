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

def write_basis_canvas(out_path, diff_link):
    basis_path = os.path.join(ROOT, "runtime", "lattice", "graph", "basis.json")
    basis = read_json(basis_path) if os.path.exists(basis_path) else {}
    selected = basis.get("selected", [])
    peer = selected[0].get("peer", "unknown") if selected else "unknown"
    score = selected[0].get("score", 0) if selected else 0
    link_line = f"diff: [[{diff_link}]]" if diff_link else "diff: (none)"
    canvas = {
        "nodes": [
            {
                "id": "basis-text",
                "type": "text",
                "x": 40,
                "y": 40,
                "width": 300,
                "height": 120,
                "text": f"Basis Selection\\nPeer: {peer}\\nScore: {score}\\n{link_line}\\nindex: [[INDEX]]",
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
    latest_diff = ""
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
            fh.write("↩ [[INDEX]]\n\n")
            fh.write(f"# Diff {prev[:8]} → {curr[:8]}\n\n")
            for k, v in added:
                fh.write(f"+ {k}: {v}\n")
            for k, v in removed:
                fh.write(f"- {k}: {v}\n")
            for k, a, b in changed:
                fh.write(f"~ {k}: {a} → {b}\n")
        latest_diff = out_name

    # graphs
    peergraph_canvas = os.path.join(CANVAS, "PeerGraph.canvas")
    if os.path.exists(peergraph_canvas):
        # Append links to INDEX and latest diff
        with open(peergraph_canvas, "r") as fh:
            canvas = json.load(fh)
        nodes = canvas.get("nodes", [])
        nodes.append({
            "id": "peergraph-links",
            "type": "text",
            "x": 40,
            "y": 320,
            "width": 300,
            "height": 100,
            "text": f"index: [[INDEX]]\\ndiff: [[plans/diffs/{latest_diff}]]" if latest_diff else "index: [[INDEX]]",
        })
        canvas["nodes"] = nodes
        with open(os.path.join(graphs_dir, "peergraph.canvas"), "w") as fh:
            json.dump(canvas, fh, separators=(",", ":"))
    write_basis_canvas(os.path.join(graphs_dir, "basis.canvas"), f"plans/diffs/{latest_diff}" if latest_diff else "")

    # reports
    basis_flips = os.path.join(REPORTS, "basis-flip.md")
    if os.path.exists(basis_flips):
        with open(basis_flips, "r") as fh:
            content = fh.read()
        with open(os.path.join(reports_dir, "basis-flips.md"), "w") as fh:
            fh.write("↩ [[INDEX]]\n\n")
            fh.write(content)

    # phase transcripts index
    transcripts = []
    for fname in os.listdir(os.path.join(ROOT, "reports")):
        if fname.endswith(".txt"):
            transcripts.append(fname)
    transcripts.sort()
    out = os.path.join(reports_dir, "phase-transcripts.md")
    with open(out, "w") as fh:
        fh.write("↩ [[INDEX]]\n\n")
        fh.write("# Phase Transcripts\n\n")
        fh.write(f"Generated: {datetime.now(timezone.utc).isoformat()}\n\n")
        for name in transcripts:
            fh.write(f"- {name}\n")

    # doctrine projection
    doctrine_src = os.path.join(ROOT, "docs", "kernel-reconstruction.md")
    doctrine_dir = os.path.join(VAULT, "doctrine")
    if os.path.exists(doctrine_src):
        ensure_dir(doctrine_dir)
        with open(doctrine_src, "r") as fh:
            doctrine = fh.read()
        doctrine_out = os.path.join(doctrine_dir, "kernel-reconstruction.md")
        with open(doctrine_out, "w") as fh:
            fh.write("↩ [[INDEX]]\n\n")
            fh.write("# Kernel Reconstruction Doctrine (Projection Copy)\n\n")
            fh.write("This file is generated from the runtime repository.\n")
            fh.write("Do not edit here.\n\n")
            fh.write(doctrine)

    # INDEX.md
    index_path = os.path.join(VAULT, "INDEX.md")
    if not latest_diff and os.path.isdir(diffs_dir):
        diffs = [f for f in os.listdir(diffs_dir) if f.endswith(".md")]
        diffs.sort()
        if diffs:
            latest_diff = diffs[-1]

    with open(index_path, "w") as fh:
        fh.write("# Metaverse Runtime Cockpit\n\n")
        fh.write("👉 [[START.canvas]]\n\n")
        fh.write("👉 [[QUICKSTART]]\n\n")
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

    # START.canvas cockpit
    start_canvas = {
        "nodes": [],
        "edges": [],
    }

    def add_node(node_id, text, x, y):
        start_canvas["nodes"].append({
            "id": node_id,
            "type": "text",
            "x": x,
            "y": y,
            "width": 260,
            "height": 90,
            "text": text,
        })

    # State column
    add_node("state-title", "STATE\\n(index: [[INDEX]])", 40, 40)
    add_node("state-plan", "Latest Plan\\n[[plans/latest-plan.json]]\\nindex: [[INDEX]]", 40, 160)
    add_node("state-graph", "Peer Graph\\n[[graphs/peergraph.canvas]]\\nindex: [[INDEX]]", 40, 280)
    add_node("state-basis", "Basis Selection\\n[[graphs/basis.canvas]]\\nindex: [[INDEX]]", 40, 400)

    # History column
    add_node("hist-title", "HISTORY\\n(index: [[INDEX]])", 360, 40)
    add_node("hist-plans", "Plan History\\n[[plans/plan-history.md]]\\nindex: [[INDEX]]", 360, 160)
    if latest_diff:
        add_node("hist-diff", f"Latest Diff\\n[[plans/diffs/{latest_diff}]]\\nindex: [[INDEX]]", 360, 280)
    add_node("hist-flips", "Basis Flips\\n[[reports/basis-flips.md]]\\nindex: [[INDEX]]", 360, 400)

    # Evidence column
    add_node("evid-title", "EVIDENCE\\n(index: [[INDEX]])", 680, 40)
    add_node("evid-transcripts", "Transcripts\\n[[reports/phase-transcripts.md]]\\nindex: [[INDEX]]", 680, 160)
    add_node("evid-routing", "Routing Evidence\\n[[runtime/lattice/trace/routing.log]]\\nindex: [[INDEX]]", 680, 280)
    add_node("evid-discovery", "Discovery Evidence\\n[[runtime/lattice/trace/discovery.log]]\\nindex: [[INDEX]]", 680, 400)

    with open(os.path.join(VAULT, "START.canvas"), "w") as fh:
        json.dump(start_canvas, fh, separators=(",", ":"))

    # QUICKSTART
    quickstart_path = os.path.join(VAULT, "QUICKSTART.md")
    latest_diff_link = f"[[plans/diffs/{latest_diff}]]" if latest_diff else "[[plans/diffs/]]"
    with open(quickstart_path, "w") as fh:
        fh.write("# Operator Quickstart\n\n")
        fh.write("↩ [[INDEX]]\n\n")
        fh.write("This vault is a projection of the live metaverse runtime.\n\n")
        fh.write("Nothing here is authoritative.\n")
        fh.write("All files are regenerated.\n")
        fh.write("Do not edit vault files.\n\n")
        fh.write("---\n\n")
        fh.write("## Step 1 — Check current state\n\n")
        fh.write("Open:\n\n")
        fh.write("[[plans/latest-plan.json]]\n\n")
        fh.write("Verify:\n\n")
        fh.write("- a peer is selected\n")
        fh.write("- bus endpoint exists\n")
        fh.write("- no empty fields\n\n")
        fh.write("If missing → routing failure.\n\n")
        fh.write("---\n\n")
        fh.write("## Step 2 — Check recent plan changes\n\n")
        fh.write("Open:\n\n")
        fh.write("[[plans/plan-history.md]]\n\n")
        fh.write("Healthy behavior:\n\n")
        fh.write("- occasional hash changes\n")
        fh.write("- stable selection under steady network\n\n")
        fh.write("Warning signs:\n\n")
        fh.write("- rapid hash churn\n")
        fh.write("- repeated oscillation\n")
        fh.write("- empty plan entries\n\n")
        fh.write("---\n\n")
        fh.write("## Step 3 — Inspect latest diff\n\n")
        fh.write("Open:\n\n")
        fh.write(f"{latest_diff_link}\n\n")
        fh.write("This explains why the system re-bound.\n\n")
        fh.write("Look for:\n\n")
        fh.write("- peer change\n")
        fh.write("- bus endpoint change\n")
        fh.write("- RTT shifts\n\n")
        fh.write("Unexpected diffs require investigation.\n\n")
        fh.write("---\n\n")
        fh.write("## Step 4 — Verify runtime health\n\n")
        fh.write("Open:\n\n")
        fh.write("[[reports/phase-transcripts.md]]\n\n")
        fh.write("Healthy system shows:\n\n")
        fh.write("PASS emits bytes  \n")
        fh.write("FAIL delta == 0  \n")
        fh.write("HALT explicit\n\n")
        fh.write("If FAIL emits bytes → invariant breach.\n\n")
        fh.write("Stop immediately.\n\n")
        fh.write("---\n\n")
        fh.write("## Step 5 — Visual overview\n\n")
        fh.write("Open:\n\n")
        fh.write("[[START.canvas]]\n\n")
        fh.write("This is the cockpit map.\n\n")
        fh.write("Use it to navigate state, history, and evidence.\n\n")
        fh.write("---\n\n")
        fh.write("## Rules of operation\n\n")
        fh.write("- Vault is read-only projection\n")
        fh.write("- Runtime truth lives in repository\n")
        fh.write("- HALT must never emit bytes\n")
        fh.write("- Authority is upstream of all adapters\n")
        fh.write("- Projection artifacts are disposable\n\n")
        fh.write("If unsure:\n\n")
        fh.write("return to [[INDEX]]\n")

if __name__ == "__main__":
    export()
    print(VAULT)
