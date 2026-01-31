#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LOG_DIR="${1:-$ROOT/runtime/sync-world/state/logs}"
OUT_LOG="${2:-$ROOT/runtime/sync-world/state/merged.jsonl}"

mkdir -p "$(dirname "$OUT_LOG")"

python3 - <<PY
import json
import os
import sys

log_dir = "${LOG_DIR}"
out_log = "${OUT_LOG}"

items = []
if os.path.isdir(log_dir):
    for name in os.listdir(log_dir):
        if not name.endswith('.jsonl'):
            continue
        path = os.path.join(log_dir, name)
        with open(path, 'r') as fh:
            for line in fh:
                line = line.strip()
                if not line:
                    continue
                env = json.loads(line)
                peer = env.get('peer')
                seq = env.get('seq')
                items.append((peer, seq, env))

items.sort(key=lambda x: (str(x[0]), int(x[1]) if isinstance(x[1], int) else int(x[1])))

with open(out_log, 'w') as out:
    for _, _, env in items:
        out.write(json.dumps(env, separators=(",", ":")) + "\n")
PY

sed -n '1,200p' "$OUT_LOG"
