#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SID_ACCEPT_DIR="$ROOT/runtime/tetragrammatron/fixtures/identity/sid/accept"
SID_REJECT_DIR="$ROOT/runtime/tetragrammatron/fixtures/identity/sid/must-reject"
CLOCK_ACCEPT_DIR="$ROOT/runtime/tetragrammatron/fixtures/identity/clock/accept"
CLOCK_REJECT_DIR="$ROOT/runtime/tetragrammatron/fixtures/identity/clock/must-reject"
OID_ACCEPT_DIR="$ROOT/runtime/tetragrammatron/fixtures/identity/occurrence/accept"
OID_REJECT_DIR="$ROOT/runtime/tetragrammatron/fixtures/identity/occurrence/must-reject"
COMPANION_ACCEPT_DIR="$ROOT/runtime/tetragrammatron/fixtures/seed-algebra/companion/accept"
COMPANION_REJECT_DIR="$ROOT/runtime/tetragrammatron/fixtures/seed-algebra/companion/must-reject"
WAVE27H_REPORT="$ROOT/reports/phase27H-living-xml.json"

REPORT="$ROOT/reports/phase27I-semantic-identity.json"
GOLDEN_HASH="$ROOT/golden/identity/replay-hash"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

for dir in "$SID_ACCEPT_DIR" "$SID_REJECT_DIR" "$CLOCK_ACCEPT_DIR" "$CLOCK_REJECT_DIR" "$OID_ACCEPT_DIR" "$OID_REJECT_DIR" "$COMPANION_ACCEPT_DIR" "$COMPANION_REJECT_DIR"; do
  [[ -d "$dir" ]] || { echo "missing fixture directory: $dir" >&2; exit 2; }
done
[[ -f "$WAVE27H_REPORT" ]] || { echo "missing wave27H report: $WAVE27H_REPORT" >&2; exit 2; }
[[ -f "$GOLDEN_HASH" ]] || { echo "missing golden hash: $GOLDEN_HASH" >&2; exit 2; }

mkdir -p "$(dirname "$REPORT")"

python3 - <<PY > "$TMP"
import hashlib
import json
from pathlib import Path

from runtime.tetragrammatron.identity import (
  advance_clock,
  advance_clock_steps,
  clock_to_text,
  compute_object_sid,
  compute_oid,
  compute_typed_sid,
  replay_hash,
  validate_clock,
  validate_occurrence_chain,
)
from runtime.tetragrammatron.io.seed_companion import (
  derive_seed_from_wave27h_report,
  validate_companion,
  validate_companion_wave27h_continuity,
)

sid_accept = Path(r"$SID_ACCEPT_DIR")
sid_reject = Path(r"$SID_REJECT_DIR")
clock_accept = Path(r"$CLOCK_ACCEPT_DIR")
clock_reject = Path(r"$CLOCK_REJECT_DIR")
oid_accept = Path(r"$OID_ACCEPT_DIR")
oid_reject = Path(r"$OID_REJECT_DIR")
companion_accept = Path(r"$COMPANION_ACCEPT_DIR")
companion_reject = Path(r"$COMPANION_REJECT_DIR")
wave27h_report_path = Path(r"$WAVE27H_REPORT")
wave27h_report = json.loads(wave27h_report_path.read_text(encoding="utf-8"))

sid_cases = []
for path in sorted(sid_accept.glob("*.json")):
  payload = json.loads(path.read_text(encoding="utf-8"))
  if path.name == "same-content-same-sid.json":
    got = compute_object_sid(payload["type"], payload["version"], payload["canonical"])
    assert got == payload["expected_sid"] == payload["same_again_sid"]
    sid_cases.append({"name": path.name, "status": "ok", "sid": got})
  elif path.name == "different-type-different-sid.json":
    a = compute_object_sid(payload["a_type"], payload["version"], payload["canonical"])
    b = compute_object_sid(payload["b_type"], payload["version"], payload["canonical"])
    assert a == payload["a_sid"]
    assert b == payload["b_sid"]
    assert a != b
    sid_cases.append({"name": path.name, "status": "ok", "a_sid": a, "b_sid": b})
  else:
    entries = payload["entries"]
    for e in entries:
      sid = compute_typed_sid(e["type"], e["canonical"])
      assert sid == e["sid"]
    sid_cases.append({"name": path.name, "status": "ok", "count": len(entries)})

sid_reject_cases = []
for path in sorted(sid_reject.glob("*.json")):
  payload = json.loads(path.read_text(encoding="utf-8"))
  try:
    compute_typed_sid(payload["type"], payload["canonical"])
    raise AssertionError("accepted invalid sid reject fixture")
  except Exception as exc:
    sid_reject_cases.append({"name": path.name, "status": "rejected", "error": exc.__class__.__name__})

clock_cases = []
for path in sorted(clock_accept.glob("*.json")):
  payload = json.loads(path.read_text(encoding="utf-8"))
  if path.name == "sequence-start.json":
    c = payload["start"]
    seq = [c]
    for _ in range(payload["steps"]):
      c = advance_clock(c)
      seq.append(c)
    assert seq == payload["expected_sequence"]
    clock_cases.append({"name": path.name, "status": "ok", "end": seq[-1]})
  elif path.name == "wrap.json":
    assert advance_clock(payload["start"]) == payload["after_1"]
    clock_cases.append({"name": path.name, "status": "ok", "after_1": payload["after_1"]})
  else:
    assert clock_to_text(payload["clock"]) == payload["text"]
    clock_cases.append({"name": path.name, "status": "ok", "text": payload["text"]})

clock_reject_cases = []
for path in sorted(clock_reject.glob("*.json")):
  payload = json.loads(path.read_text(encoding="utf-8"))
  try:
    validate_clock(payload["clock"])
    raise AssertionError("accepted invalid clock reject fixture")
  except Exception as exc:
    clock_reject_cases.append({"name": path.name, "status": "rejected", "error": exc.__class__.__name__})

oid_cases = []
replay_items = []
for path in sorted(oid_accept.glob("*.json")):
  payload = json.loads(path.read_text(encoding="utf-8"))
  if isinstance(payload, dict) and set(payload.keys()) == {"v", "authority", "head_oid", "occurrences"}:
    validate_occurrence_chain(payload)
    h = replay_hash(payload)
    replay_items.append(h)
    oid_cases.append({"name": path.name, "status": "ok", "replay_hash": h})
  elif "clock_a" in payload and "clock_b" in payload:
    a = compute_oid(payload["clock_a"], payload["sid"], payload["prev_oid"])
    b = compute_oid(payload["clock_b"], payload["sid"], payload["prev_oid"])
    assert a == payload["oid_a"]
    assert b == payload["oid_b"]
    assert a != b
    oid_cases.append({"name": path.name, "status": "ok", "oid_a": a, "oid_b": b})
  elif "prev_a" in payload and "prev_b" in payload:
    a = compute_oid(payload["clock"], payload["sid"], payload["prev_a"])
    b = compute_oid(payload["clock"], payload["sid"], payload["prev_b"])
    assert a == payload["oid_a"]
    assert b == payload["oid_b"]
    assert a != b
    oid_cases.append({"name": path.name, "status": "ok", "oid_a": a, "oid_b": b})
  else:
    raise AssertionError(f"unknown oid accept fixture format: {path.name}")

oid_reject_cases = []
for path in sorted(oid_reject.glob("*.json")):
  payload = json.loads(path.read_text(encoding="utf-8"))
  try:
    validate_occurrence_chain(payload)
    raise AssertionError("accepted invalid oid reject fixture")
  except Exception as exc:
    oid_reject_cases.append({"name": path.name, "status": "rejected", "error": exc.__class__.__name__})

companion_cases = []
derived_seed = derive_seed_from_wave27h_report(wave27h_report)
cross_wave_continuity = {"status": "skipped"}
for path in sorted(companion_accept.glob("*.json")):
  payload = json.loads(path.read_text(encoding="utf-8"))
  validate_companion(payload)
  if path.name == "from-wave27h-report.json":
    validate_companion_wave27h_continuity(wave27h_report, payload)
    occ_state = json.loads((oid_accept / "from-wave27h-report.json").read_text(encoding="utf-8"))
    validate_occurrence_chain(occ_state)
    head = next(entry for entry in occ_state["occurrences"] if entry["oid"] == occ_state["head_oid"])
    tail = next(entry for entry in occ_state["occurrences"] if entry["prev_oid"] is None)
    linked_sid = payload["links"]["derived_from"][0] if payload["links"]["derived_from"] else None
    if linked_sid != head["sid"] or tail["oid"] != payload["prev_oid"]:
      raise AssertionError("cross-wave continuity mismatch between companion and occurrence chain")
    cross_wave_continuity = {
      "status": "ok",
      "companion_sid": payload["sid"],
      "occurrence_head_sid": head["sid"],
      "derived_from_sid": linked_sid,
      "linked_prev_oid": payload["prev_oid"],
    }
  companion_cases.append({
    "name": path.name,
    "status": "ok",
    "sid": payload["sid"],
    "oid": payload["oid"],
  })

companion_reject_cases = []
for path in sorted(companion_reject.glob("*.json")):
  payload = json.loads(path.read_text(encoding="utf-8"))
  try:
    validate_companion(payload)
    raise AssertionError("accepted invalid companion reject fixture")
  except Exception as exc:
    companion_reject_cases.append({"name": path.name, "status": "rejected", "error": exc.__class__.__name__})

summary = {
  "sid_accept": len(sid_cases),
  "sid_reject": len(sid_reject_cases),
  "clock_accept": len(clock_cases),
  "clock_reject": len(clock_reject_cases),
  "oid_accept": len(oid_cases),
  "oid_reject": len(oid_reject_cases),
  "companion_accept": len(companion_cases),
  "companion_reject": len(companion_reject_cases),
}
report = {
  "v": "phase27I.identity_occurrence_gate.v0",
  "authority": "advisory",
  "wave27h_seed": derived_seed,
  "cross_wave_continuity": cross_wave_continuity,
  "summary": summary,
  "sid": {"accept": sid_cases, "must_reject": sid_reject_cases},
  "clock": {"accept": clock_cases, "must_reject": clock_reject_cases},
  "oid": {
    "accept": oid_cases,
    "must_reject": oid_reject_cases,
    "replay_digest": "sha256:" + hashlib.sha256(json.dumps(replay_items, sort_keys=True, separators=(",", ":")).encode("utf-8")).hexdigest(),
  },
  "companion": {"accept": companion_cases, "must_reject": companion_reject_cases},
}
print(json.dumps(report, sort_keys=True, separators=(",", ":"), ensure_ascii=False))
PY

cp "$TMP" "$REPORT"

want="$(tr -d '\n' < "$GOLDEN_HASH")"
got="sha256:$(sha256sum "$TMP" | awk '{print $1}')"
if [[ "$want" != "$got" ]]; then
  echo "identity replay hash mismatch: expected $want got $got" >&2
  sed -n '1,220p' "$TMP" >&2
  exit 1
fi

echo "ok identity gate"
