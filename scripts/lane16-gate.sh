#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACCEPT_DIR="$ROOT/runtime/tetragrammatron/fixtures/lane16/accept"
REJECT_DIR="$ROOT/runtime/tetragrammatron/fixtures/lane16/must-reject"
REPORT="$ROOT/reports/phase27K-lane16.json"
GOLDEN_HASH="$ROOT/golden/lane16/replay-hash"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

[[ -d "$ACCEPT_DIR" ]] || { echo "missing accept fixture directory: $ACCEPT_DIR" >&2; exit 2; }
[[ -d "$REJECT_DIR" ]] || { echo "missing reject fixture directory: $REJECT_DIR" >&2; exit 2; }
[[ -f "$GOLDEN_HASH" ]] || { echo "missing golden hash: $GOLDEN_HASH" >&2; exit 2; }

mkdir -p "$(dirname "$REPORT")"

python3 - <<PY > "$TMP"
import json
from pathlib import Path

from runtime.tetragrammatron.io.lane16 import (
  Lane16Error,
  Lane16System,
  SCHEMA_V,
  encode_lane_state,
  fano_pcg_check,
  lane_pair_digest,
  lane_phase,
  lane_sid,
  lane_step,
)

accept_dir = Path(r"$ACCEPT_DIR")
reject_dir = Path(r"$REJECT_DIR")

accept = []
summary = {
  "lane_basic": 0,
  "lane_group": 0,
  "lane_full": 0,
  "lane_invariant": 0,
  "must_reject": 0,
}

for path in sorted(accept_dir.rglob("*.json")):
  payload = json.loads(path.read_text(encoding="utf-8"))
  kind = payload["kind"]
  if kind == "lane_basic":
    got_next = lane_step(payload["state"])
    got_phase = lane_phase(payload["lane_idx"], payload["state"])
    got_sid = lane_sid(payload["lane_idx"], payload["state"])
    got_codes = encode_lane_state(payload["lane_idx"], payload["state"])
    assert got_next == payload["expected_next"]
    assert got_phase == payload["expected_phase"]
    assert got_sid == payload["expected_sid"]
    assert got_codes == payload["expected_codes"]
    summary["lane_basic"] += 1
    accept.append({"name": path.name, "kind": kind, "sid": got_sid, "phase": got_phase})
  elif kind == "lane_group":
    start = payload["group"] * 4
    got = fano_pcg_check(payload["states"], start)
    assert got == payload["expected_sync"]
    summary["lane_group"] += 1
    accept.append({"name": path.name, "kind": kind, "sync": got})
  elif kind == "lane_full":
    system = Lane16System.init(payload["initial_states"])
    for _ in range(payload["steps"]):
      system.tick()
    assert system.clock == payload["expected_clock"]
    assert system.lane_states == payload["expected_states"]
    assert system.sid == payload["expected_sid"]
    assert system.sync_all() == payload["expected_sync_all"]
    summary["lane_full"] += 1
    accept.append({"name": path.name, "kind": kind, "sid": system.sid, "sync_all": system.sync_all()})
  elif kind == "lane_invariant":
    got = lane_pair_digest(payload["states"])
    assert got == payload["expected_digest"]
    summary["lane_invariant"] += 1
    accept.append({"name": path.name, "kind": kind, "digest": got})
  else:
    raise AssertionError(f"unknown accept fixture kind: {kind}")

reject = []
for path in sorted(reject_dir.glob("*.json")):
  payload = json.loads(path.read_text(encoding="utf-8"))
  kind = payload["kind"]
  try:
    if kind == "lane_basic":
      _ = lane_phase(payload["lane_idx"], payload["state"])
    elif kind == "lane_group":
      start = payload["group"] * 4
      got = fano_pcg_check(payload["states"], start)
      if got != payload["expected_sync"]:
        raise Lane16Error("group sync mismatch")
    elif kind == "lane_codes":
      _ = encode_lane_state(payload["lane_idx"], payload["state"])
    elif kind == "lane_full":
      system = Lane16System.init(payload["initial_states"])
      for _ in range(payload.get("steps", 0)):
        system.tick()
      if system.sync_all() != payload["expected_sync_all"]:
        raise Lane16Error("system sync mismatch")
    else:
      raise Lane16Error("unknown reject kind")
    raise AssertionError(f"accepted invalid reject fixture: {path.name}")
  except Exception as exc:
    summary["must_reject"] += 1
    reject.append({"name": path.name, "status": "rejected", "error": exc.__class__.__name__})

sys = Lane16System.init([0] * 16)
report = {
  "v": "phase27K.lane16_gate.v0",
  "authority": "advisory",
  "runtime_schema": SCHEMA_V,
  "summary": summary,
  "accept": accept,
  "must_reject": reject,
  "sample_report": sys.to_report(),
}

print(json.dumps(report, sort_keys=True, separators=(",", ":"), ensure_ascii=False))
PY

cp "$TMP" "$REPORT"

want="$(tr -d '\n' < "$GOLDEN_HASH")"
got="sha256:$(sha256sum "$TMP" | awk '{print $1}')"
if [[ "$want" != "$got" ]]; then
  echo "lane16 replay hash mismatch: expected $want got $got" >&2
  sed -n '1,220p' "$TMP" >&2
  exit 1
fi

echo "ok lane16 gate"
