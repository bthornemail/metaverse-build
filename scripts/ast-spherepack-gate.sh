#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACCEPT_FIXTURE="$ROOT/runtime/tetragrammatron/fixtures/ast-spherepack/accept/python-sample.json"
MUST_REJECT_DIR="$ROOT/runtime/tetragrammatron/fixtures/ast-spherepack/must-reject"
GOLDEN_BUNDLE="$ROOT/golden/ast-spherepack/python-sample.bundle.json"
GOLDEN_HASH="$ROOT/golden/ast-spherepack/replay-hash"
TMP_BUNDLE="$(mktemp)"
trap 'rm -f "$TMP_BUNDLE"' EXIT

bash "$ROOT/scripts/ast-spherepack-golden.sh" >/dev/null
bash "$ROOT/scripts/ast-spherepack-must-reject.sh" >/dev/null
bash "$ROOT/scripts/kg-golden.sh" >/dev/null
bash "$ROOT/scripts/kg-must-reject.sh" >/dev/null

python3 - <<PY > "$TMP_BUNDLE"
import json
from runtime.tetragrammatron.io.ast_spherepack import compress_input_payload
from runtime.tetragrammatron.pure.common import canonical_json

with open(r"$ACCEPT_FIXTURE", "r", encoding="utf-8") as f:
  payload = json.load(f)
bundle = compress_input_payload(payload)
print(canonical_json(bundle))
PY

if ! cmp -s "$TMP_BUNDLE" "$GOLDEN_BUNDLE"; then
  echo "ast spherepack golden bundle mismatch" >&2
  echo "--- generated ---" >&2
  sed -n '1,120p' "$TMP_BUNDLE" >&2
  echo "--- expected ---" >&2
  sed -n '1,120p' "$GOLDEN_BUNDLE" >&2
  exit 1
fi

want="$(tr -d '\n' < "$GOLDEN_HASH")"
got="sha256:$(sha256sum "$TMP_BUNDLE" | awk '{print $1}')"
if [[ "$want" != "$got" ]]; then
  echo "ast spherepack hash mismatch: expected $want got $got" >&2
  exit 1
fi

for bad_json in "$MUST_REJECT_DIR"/*.json; do
  if [[ ! -f "$bad_json" ]]; then
    continue
  fi
  set +e
  err="$(python3 - <<PY 2>&1 >/dev/null
import json
from runtime.tetragrammatron.io.ast_spherepack import validate_input_payload
with open(r"$bad_json", "r", encoding="utf-8") as f:
  payload = json.load(f)
validate_input_payload(payload)
raise SystemExit("accepted invalid ast spherepack input")
PY
)"
  status=$?
  set -e
  if [[ $status -eq 0 ]]; then
    echo "must-reject accepted invalid input: $bad_json" >&2
    exit 1
  fi
  if ! printf '%s' "$err" | grep -Eq 'AstSpherepackError|keyset mismatch|schema mismatch|supported|sources'; then
    echo "must-reject unexpected error for $bad_json: $err" >&2
    exit 1
  fi
done

echo "ok ast spherepack gate"
