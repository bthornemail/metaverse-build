#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACCEPT_DIR="$ROOT/runtime/tetragrammatron/fixtures/seed-algebra/accept"
MR_DIR="$ROOT/runtime/tetragrammatron/fixtures/seed-algebra/must-reject"
COMPANION_ACCEPT_DIR="$ROOT/runtime/tetragrammatron/fixtures/seed-algebra/companion/accept"
COMPANION_REJECT_DIR="$ROOT/runtime/tetragrammatron/fixtures/seed-algebra/companion/must-reject"
WAVE27H_REPORT="$ROOT/reports/phase27H-living-xml.json"
REPORT="$ROOT/reports/phase27J-seed-algebra.json"
GOLDEN_HASH="$ROOT/golden/seed-algebra/replay-hash"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

[[ -d "$ACCEPT_DIR" ]] || { echo "missing accept fixture directory: $ACCEPT_DIR" >&2; exit 2; }
[[ -d "$MR_DIR" ]] || { echo "missing reject fixture directory: $MR_DIR" >&2; exit 2; }
[[ -d "$COMPANION_ACCEPT_DIR" ]] || { echo "missing companion accept fixture directory: $COMPANION_ACCEPT_DIR" >&2; exit 2; }
[[ -d "$COMPANION_REJECT_DIR" ]] || { echo "missing companion reject fixture directory: $COMPANION_REJECT_DIR" >&2; exit 2; }
[[ -f "$WAVE27H_REPORT" ]] || { echo "missing wave27H report: $WAVE27H_REPORT" >&2; exit 2; }
[[ -f "$GOLDEN_HASH" ]] || { echo "missing golden hash: $GOLDEN_HASH" >&2; exit 2; }

mkdir -p "$(dirname "$REPORT")"

python3 - <<PY > "$TMP"
import json
import hashlib
from pathlib import Path

from runtime.tetragrammatron.io.seed_algebra import (
  SeedAlgebraError,
  build_seed_entity,
  closure_fixpoint,
  compose_and,
  compose_xor,
  invariant_digest,
  phase,
  validate_seed_entity,
)
from runtime.tetragrammatron.io.seed_companion import (
  derive_seed_from_wave27h_report,
  validate_companion,
  validate_companion_wave27h_continuity,
)

accept_dir = Path(r"$ACCEPT_DIR")
reject_dir = Path(r"$MR_DIR")
companion_accept_dir = Path(r"$COMPANION_ACCEPT_DIR")
companion_reject_dir = Path(r"$COMPANION_REJECT_DIR")
wave27h_report = json.loads(Path(r"$WAVE27H_REPORT").read_text(encoding="utf-8"))

accept = []
summary = {
  "seed_basic": 0,
  "closure": 0,
  "phase": 0,
  "composition": 0,
  "entity": 0,
  "invariant": 0,
  "companion_accept": 0,
  "companion_reject": 0,
  "reject": 0,
}

for path in sorted(accept_dir.rglob("*.json")):
  payload = json.loads(path.read_text(encoding="utf-8"))
  kind = payload.get("kind")
  if kind == "seed_basic":
    seed = payload["seed"]
    if seed != payload["expected_seed"]:
      raise AssertionError(f"seed_basic mismatch in {path.name}")
    summary["seed_basic"] += 1
    accept.append({"name": path.name, "kind": kind, "seed": seed})
  elif kind == "closure":
    got = closure_fixpoint(payload["seed"])
    if got != payload["expected_header"]:
      raise AssertionError(f"closure mismatch in {path.name}")
    summary["closure"] += 1
    accept.append({"name": path.name, "kind": kind, "header": got})
  elif kind == "phase":
    got = phase(payload["seed"])
    if got != payload["expected_phase"]:
      raise AssertionError(f"phase mismatch in {path.name}")
    summary["phase"] += 1
    accept.append({"name": path.name, "kind": kind, "phase": got})
  elif kind == "composition":
    op = payload["op"]
    if op == "xor":
      got = compose_xor(payload["a"], payload["b"])
    elif op == "and":
      got = compose_and(payload["a"], payload["b"])
    elif op == "shared_phase":
      got = phase(compose_and(payload["a"], payload["b"]))
    else:
      raise AssertionError(f"unknown composition op in accept fixture {path.name}")
    if got != payload["expected"]:
      raise AssertionError(f"composition mismatch in {path.name}")
    summary["composition"] += 1
    accept.append({"name": path.name, "kind": kind, "op": op, "value": got})
  elif kind == "entity":
    validate_seed_entity(payload["entity"])
    summary["entity"] += 1
    accept.append({"name": path.name, "kind": kind, "sid": payload["entity"]["sid"]})
  elif kind == "invariant":
    digest = invariant_digest()
    if digest != payload["expected_digest"]:
      raise AssertionError(f"invariant digest mismatch in {path.name}")
    summary["invariant"] += 1
    accept.append({"name": path.name, "kind": kind, "digest": digest})
  else:
    raise AssertionError(f"unknown accept fixture kind in {path.name}: {kind}")

reject = []
for path in sorted(reject_dir.rglob("*.json")):
  payload = json.loads(path.read_text(encoding="utf-8"))
  kind = payload.get("kind")
  try:
    if kind == "seed_basic":
      _ = closure_fixpoint(payload["seed"])
    elif kind == "composition":
      op = payload["op"]
      if op == "xor":
        _ = compose_xor(payload["a"], payload["b"])
      elif op == "and":
        _ = compose_and(payload["a"], payload["b"])
      elif op == "shared_phase":
        _ = phase(compose_and(payload["a"], payload["b"]))
      else:
        raise SeedAlgebraError("unsupported composition op")
    elif kind == "entity":
      validate_seed_entity(payload["entity"])
    elif kind == "clock_projection":
      from runtime.tetragrammatron.identity import validate_clock
      validate_clock(payload["clock"])
    else:
      raise SeedAlgebraError("unknown reject fixture kind")
    raise AssertionError(f"accepted invalid reject fixture: {path.name}")
  except Exception as exc:
    summary["reject"] += 1
    reject.append({"name": path.name, "status": "rejected", "error": exc.__class__.__name__})

companion_accept = []
derived_seed = derive_seed_from_wave27h_report(wave27h_report)
for path in sorted(companion_accept_dir.glob("*.json")):
  payload = json.loads(path.read_text(encoding="utf-8"))
  validate_companion(payload)
  if path.name == "from-wave27h-report.json":
    validate_companion_wave27h_continuity(wave27h_report, payload)
  summary["companion_accept"] += 1
  companion_accept.append({"name": path.name, "sid": payload["sid"], "oid": payload["oid"], "status": "ok"})

companion_reject = []
for path in sorted(companion_reject_dir.glob("*.json")):
  payload = json.loads(path.read_text(encoding="utf-8"))
  try:
    validate_companion(payload)
    raise AssertionError(f"accepted invalid companion reject fixture: {path.name}")
  except Exception as exc:
    summary["companion_reject"] += 1
    companion_reject.append({"name": path.name, "status": "rejected", "error": exc.__class__.__name__})

report = {
  "v": "phase27J.seed_algebra_gate.v0",
  "authority": "advisory",
  "wave27h_seed": derived_seed,
  "summary": summary,
  "accept": accept,
  "companion": {
    "accept": companion_accept,
    "must_reject": companion_reject,
  },
  "must_reject": reject,
  "invariant_digest": invariant_digest(),
}

print(json.dumps(report, sort_keys=True, separators=(",", ":"), ensure_ascii=False))
PY

cp "$TMP" "$REPORT"

want="$(tr -d '\n' < "$GOLDEN_HASH")"
got="sha256:$(sha256sum "$TMP" | awk '{print $1}')"
if [[ "$want" != "$got" ]]; then
  echo "seed-algebra replay hash mismatch: expected $want got $got" >&2
  sed -n '1,220p' "$TMP" >&2
  exit 1
fi

echo "ok seed-algebra gate"
