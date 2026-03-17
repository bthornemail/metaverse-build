#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACCEPT_FIXTURE="$ROOT/runtime/tetragrammatron/fixtures/klein/accept/canonical-60.json"
MUST_REJECT_DIR="$ROOT/runtime/tetragrammatron/fixtures/klein/must-reject"
GOLDEN_HASH_FILE="$ROOT/golden/klein-blackboard/replay-hash"

if [[ ! -f "$ACCEPT_FIXTURE" ]]; then
  echo "missing canonical fixture: $ACCEPT_FIXTURE" >&2
  exit 2
fi
if [[ ! -f "$GOLDEN_HASH_FILE" ]]; then
  echo "missing golden hash: $GOLDEN_HASH_FILE" >&2
  exit 2
fi

want="$(tr -d '\n' < "$GOLDEN_HASH_FILE")"
got="sha256:$(sha256sum "$ACCEPT_FIXTURE" | awk '{print $1}')"
if [[ "$want" != "$got" ]]; then
  echo "klein fixture golden mismatch: expected $want got $got" >&2
  exit 1
fi

python3 - <<PY
import json
from runtime.tetragrammatron.io.klein_blackboard import validate_klein_incidence, min_hamming_distance

with open(r"$ACCEPT_FIXTURE", "r", encoding="utf-8") as f:
  payload = json.load(f)

points = payload["points"]
stats = validate_klein_incidence(points)
if stats["point_count"] != 60 or stats["matching_class_count"] != 15 or stats["line_count"] != 15:
  raise SystemExit("unexpected incidence stats")
if min_hamming_distance(points) < 2:
  raise SystemExit("minimum hamming distance violation")
PY

for bad_json in "$MUST_REJECT_DIR"/*.json; do
  if [[ ! -f "$bad_json" ]]; then
    continue
  fi
  set +e
  err="$(python3 - <<PY 2>&1 >/dev/null
import json
from runtime.tetragrammatron.io.klein_blackboard import validate_klein_incidence

with open(r"$bad_json", "r", encoding="utf-8") as f:
  payload = json.load(f)
validate_klein_incidence(payload["points"])
raise SystemExit("accepted invalid klein fixture")
PY
)"
  status=$?
  set -e
  if [[ $status -eq 0 ]]; then
    echo "must-reject accepted invalid fixture: $bad_json" >&2
    exit 1
  fi
  if ! printf '%s' "$err" | grep -Eq 'KleinBlackboardError|expected exactly|duplicate|perfect matching|line|co-occur'; then
    echo "must-reject unexpected error for $bad_json: $err" >&2
    exit 1
  fi
done

echo "ok klein gate"
