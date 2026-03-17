#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACCEPT="$ROOT/runtime/tetragrammatron/fixtures/control-superposition/accept/canonical.json"
MR_DIR="$ROOT/runtime/tetragrammatron/fixtures/control-superposition/must-reject"
REPORT="$ROOT/reports/phase27G-control-superposition.json"
GOLDEN_HASH="$ROOT/golden/control-superposition/replay-hash"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

if [[ ! -f "$ACCEPT" ]]; then
  echo "missing accept fixture: $ACCEPT" >&2
  exit 2
fi
if [[ ! -f "$GOLDEN_HASH" ]]; then
  echo "missing golden hash: $GOLDEN_HASH" >&2
  exit 2
fi

mkdir -p "$(dirname "$REPORT")"

python3 - <<PY > "$TMP"
import json
from runtime.tetragrammatron.io.control_superposition import canonical_control_superposition
with open(r"$ACCEPT", "r", encoding="utf-8") as f:
  payload = json.load(f)
print(canonical_control_superposition(payload))
PY

# canonical golden output for inspection/reporting
cp "$TMP" "$REPORT"

want="$(tr -d '\n' < "$GOLDEN_HASH")"
got="sha256:$(sha256sum "$TMP" | awk '{print $1}')"
if [[ "$want" != "$got" ]]; then
  echo "control-superposition replay hash mismatch: expected $want got $got" >&2
  sed -n '1,120p' "$TMP" >&2
  exit 1
fi

for bad in "$MR_DIR"/*.json; do
  [[ -f "$bad" ]] || continue
  set +e
  err="$(python3 - <<PY 2>&1 >/dev/null
import json
from runtime.tetragrammatron.io.control_superposition import canonical_control_superposition
with open(r"$bad", "r", encoding="utf-8") as f:
  payload = json.load(f)
canonical_control_superposition(payload)
print("accepted invalid fixture")
raise SystemExit(1)
PY
)"
  status=$?
  set -e
  if [[ $status -eq 0 ]]; then
    echo "must-reject accepted invalid fixture: $bad" >&2
    exit 1
  fi
  if ! printf '%s' "$err" | grep -Eq 'ControlSuperpositionError|mismatch|must be'; then
    echo "must-reject unexpected error for $bad: $err" >&2
    exit 1
  fi
done

echo "ok control-superposition gate"
