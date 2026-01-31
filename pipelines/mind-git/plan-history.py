#!/usr/bin/env python3
import json
import os
import hashlib
from datetime import datetime, timezone

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT_ROOT = os.path.join(ROOT, "projections", "mind-git")
REPORTS = os.path.join(OUT_ROOT, "reports")
PLAN_STORE = os.path.join(OUT_ROOT, "plan-history")
INDEX_FILE = os.path.join(PLAN_STORE, "index.jsonl")
os.makedirs(REPORTS, exist_ok=True)
os.makedirs(PLAN_STORE, exist_ok=True)

routing_log = os.path.join(ROOT, "runtime", "lattice", "trace", "routing.log")
discovery_log = os.path.join(ROOT, "runtime", "lattice", "trace", "discovery.log")
current_plan = os.path.join(ROOT, "runtime", "lattice", "plan", "connection-plan.json")

def sha256_obj(obj):
    data = json.dumps(obj, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(data).hexdigest()

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

def extract_plan_meta(plan_path):
    plan = load_json(plan_path)
    attachments = plan.get("attachments", [])
    first = attachments[0] if attachments else {}
    return {
        "plan_path": plan_path,
        "peer": first.get("peer", "unknown"),
        "trace_tcp": first.get("trace_tcp", ""),
        "trace_fifo": first.get("trace_fifo", ""),
        "plan": plan,
    }

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

def beacon_evidence(events, peer):
    for ev in reversed(events):
        raw = ev.get("raw")
        if not raw:
            continue
        try:
            beacon = json.loads(raw)
        except Exception:
            continue
        if beacon.get("node") == peer:
            rtt = beacon.get("rtt_ms", "unknown")
            return f"beacon({peer}, rtt={rtt})"
    return "beacon(unknown)"

routing = parse_jsonl(routing_log)
discovery = parse_jsonl(discovery_log)

def latest_rebind_time(events):
    times = [ev.get("t", 0) for ev in events if ev.get("type") == "rebind"]
    return max(times) if times else 0

entries = []

# Ensure current plan is snapshotted and indexed
if os.path.exists(current_plan):
    plan_obj = load_json(current_plan)
    plan_hash = sha256_obj(plan_obj)
    snapshot = os.path.join(PLAN_STORE, f"{plan_hash}.json")
    if not os.path.exists(snapshot):
        with open(snapshot, "w") as fh_out:
            json.dump(plan_obj, fh_out, separators=(",", ":"), sort_keys=True)
    seen = set()
    if os.path.exists(INDEX_FILE):
        for rec in parse_jsonl(INDEX_FILE):
            seen.add(rec.get("hash"))
    if plan_hash not in seen:
        t = latest_rebind_time(routing)
        with open(INDEX_FILE, "a") as fh:
            fh.write(json.dumps({"t": t, "hash": plan_hash}, separators=(",", ":")) + "\n")

# Build entries from index
index = parse_jsonl(INDEX_FILE)
for rec in index:
    h = rec.get("hash")
    snapshot = os.path.join(PLAN_STORE, f"{h}.json")
    if not os.path.exists(snapshot):
        continue
    meta = extract_plan_meta(snapshot)
    entries.append({
        "t": rec.get("t", 0),
        "hash": h,
        **meta,
    })

entries.sort(key=lambda e: (e["t"], e["hash"]))

# De-duplicate consecutive identical hashes
deduped = []
last_hash = None
for e in entries:
    if e["hash"] == last_hash:
        continue
    deduped.append(e)
    last_hash = e["hash"]
entries = deduped

out_path = os.path.join(REPORTS, "plan-history.md")
with open(out_path, "w") as fh:
    fh.write("# Plan History\n\n")
    fh.write(f"Generated: {datetime.now(timezone.utc).isoformat()}\n\n")
    prev = None
    for e in entries:
        fh.write(f"## {e['hash'][:8]}\n")
        fh.write(f"- Timestamp: {e['t']}\n")
        fh.write(f"- Selected peer: {e['peer']}\n")
        if e["trace_tcp"]:
            fh.write(f"- Bus: {e['trace_tcp']}\n")
        elif e["trace_fifo"]:
            fh.write(f"- Bus: {e['trace_fifo']}\n")
        fh.write(f"- Evidence: {beacon_evidence(discovery, e['peer'])}\n")
        if prev is not None:
            fh.write(f"- Delta from previous: {prev['peer']} → {e['peer']}\n")
            added, removed, changed = structural_diff(prev["plan"], e["plan"])
            fh.write(f"\n### Diff from {prev['hash'][:8]}\n")
            for k, v in added:
                fh.write(f"+ {k}: {v}\n")
            for k, v in removed:
                fh.write(f"- {k}: {v}\n")
            for k, a, b in changed:
                fh.write(f"~ {k}: {a} → {b}\n")
        fh.write("\n")
        prev = e

print(out_path)
