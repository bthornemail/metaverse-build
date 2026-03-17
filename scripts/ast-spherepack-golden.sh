#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACCEPT_DIR="$ROOT/runtime/tetragrammatron/fixtures/ast-spherepack/crosslang/accept"
GOLDEN_DIR="$ROOT/golden/ast-spherepack"
TMP_OUT="$(mktemp)"
TMP_PROOF="$(mktemp)"
trap 'rm -f "$TMP_OUT" "$TMP_PROOF"' EXIT

for fixture in "$ACCEPT_DIR"/*.json; do
  [[ -f "$fixture" ]] || continue
  base="$(basename "$fixture" .json)"
  golden="$GOLDEN_DIR/$base.output.json"
  if [[ ! -f "$golden" ]]; then
    echo "missing golden output: $golden" >&2
    exit 2
  fi
  python3 - <<PY > "$TMP_OUT"
import json
from runtime.tetragrammatron.io.ast_spherepack import compress_ast
from runtime.tetragrammatron.pure.common import canonical_json
with open(r"$fixture", "r", encoding="utf-8") as f:
  payload = json.load(f)
result = compress_ast(payload["source"], payload["language"], module=payload["module"])
print(canonical_json(result))
PY
  if ! cmp -s "$TMP_OUT" "$golden"; then
    echo "ast spherepack golden mismatch for $base" >&2
    echo "--- generated ---" >&2
    sed -n '1,120p' "$TMP_OUT" >&2
    echo "--- expected ---" >&2
    sed -n '1,120p' "$golden" >&2
    exit 1
  fi
done

python3 - <<PY > "$TMP_PROOF"
import json
import glob
import os
from runtime.tetragrammatron.io.ast_spherepack import compress_ast
from runtime.tetragrammatron.pure.common import canonical_json

py_paths = sorted(glob.glob(os.path.join(r"$ACCEPT_DIR", "*.python.json")))
cases = []
for py_path in py_paths:
  stem = os.path.basename(py_path).replace(".python.json", "")
  js_path = os.path.join(r"$ACCEPT_DIR", f"{stem}.javascript.json")
  if not os.path.exists(js_path):
    raise SystemExit(f"missing javascript pair fixture for {stem}")
  with open(py_path, "r", encoding="utf-8") as f:
    py_fixture = json.load(f)
  with open(js_path, "r", encoding="utf-8") as f:
    js_fixture = json.load(f)
  py = compress_ast(py_fixture["source"], py_fixture["language"], module=py_fixture["module"])
  js = compress_ast(js_fixture["source"], js_fixture["language"], module=js_fixture["module"])
  equivalent = py["point"] == js["point"] and py["line"] == js["line"] and py["coords_digest"] == js["coords_digest"]
  if not equivalent:
    raise SystemExit(f"cross-language equivalence failed for {stem}")
  cases.append({
    "name": stem,
    "python": {"point": py["point"], "line": py["line"], "coords_digest": py["coords_digest"]},
    "javascript": {"point": js["point"], "line": js["line"], "coords_digest": js["coords_digest"]},
    "equivalent": equivalent,
  })

proof = {
  "v": "tetragrammatron.ast_spherepack.crosslang_proof.v0",
  "authority": "advisory",
  "cases": cases,
  "all_equivalent": all(case["equivalent"] for case in cases),
}
print(canonical_json(proof))
PY

if ! cmp -s "$TMP_PROOF" "$GOLDEN_DIR/crosslang-proof.json"; then
  echo "crosslang proof golden mismatch" >&2
  exit 1
fi

want="$(tr -d '\n' < "$GOLDEN_DIR/crosslang-proof.replay-hash")"
got="sha256:$(sha256sum "$TMP_PROOF" | awk '{print $1}')"
if [[ "$want" != "$got" ]]; then
  echo "crosslang proof hash mismatch: expected $want got $got" >&2
  exit 1
fi

echo "ok ast-spherepack golden"
