#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT="$ROOT/reports/phase27F-fano-scheduler.json"
GOLDEN_HASH="$ROOT/golden/fano-scheduler/replay-hash"

mkdir -p "$(dirname "$REPORT")" "$(dirname "$GOLDEN_HASH")"

python3 - <<PY
import json
from runtime.tetragrammatron.io.fano_scheduler import FANO_LINES, FanoScheduler

report_path = r"$REPORT"

s = FanoScheduler()

# Deterministic process set: one process per line, starting at line head.
for line in range(1, 8):
  s.add_process(process_id=f"line-{line}", line=line)

ticks = []
for _ in range(21):
  ticks.append(s.tick())

active_lines = [t["active_line"] for t in ticks]
expected_prefix = [1, 2, 3, 4, 5, 6, 7] * 3
if active_lines != expected_prefix:
  raise SystemExit("fano scheduler active-line sequence mismatch")

payload = {
  "v": "phase27F.fano_scheduler.v0",
  "authority": "advisory",
  "fano_lines": {str(k): list(v) for k, v in FANO_LINES.items()},
  "tetrahedral_superposition": {
    "v": "tetragrammatron.control_superposition.v0",
    "layers": [
      {"name": "ABCD", "codes": ["FS", "GS", "RS", "US"]},
      {"name": "abcd", "codes": ["fs", "gs", "rs", "us"]},
      {"name": "a'b'c'd'", "codes": ["𝔣𝔰", "𝔤𝔰", "𝔯𝔰", "𝔲𝔰"]},
    ],
    "observer_centroid_ref": [3, 3, 3],
  },
  "global_ticks": s.global_ticks,
  "active_line_sequence": active_lines,
  "final_snapshot": s.process_snapshot(),
  "tick_receipts": ticks,
}

with open(report_path, "w", encoding="utf-8") as f:
  f.write(json.dumps(payload, sort_keys=True, separators=(",", ":"), ensure_ascii=False))
  f.write("\\n")
PY

if [[ ! -f "$GOLDEN_HASH" ]]; then
  echo "missing golden hash: $GOLDEN_HASH" >&2
  exit 2
fi

want="$(tr -d '\n' < "$GOLDEN_HASH")"
got="sha256:$(sha256sum "$REPORT" | awk '{print $1}')"
if [[ "$want" != "$got" ]]; then
  echo "fano-scheduler replay hash mismatch: expected $want got $got" >&2
  sed -n '1,120p' "$REPORT" >&2
  exit 1
fi

echo "ok fano-scheduler gate"
