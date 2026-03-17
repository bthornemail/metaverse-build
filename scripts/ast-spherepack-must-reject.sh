#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MR_DIR="$ROOT/runtime/tetragrammatron/fixtures/ast-spherepack/crosslang/must-reject"

for fixture in "$MR_DIR"/*.json; do
  [[ -f "$fixture" ]] || continue
  set +e
  err="$(python3 - <<PY 2>&1 >/dev/null
import json
from runtime.tetragrammatron.io.ast_spherepack import compress_ast
with open(r"$fixture", "r", encoding="utf-8") as f:
  payload = json.load(f)
compress_ast(payload["source"], payload["language"], module=payload.get("module", "crosslang.reject"))
raise SystemExit("accepted invalid crosslang fixture")
PY
)"
  status=$?
  set -e
  if [[ $status -eq 0 ]]; then
    echo "must-reject accepted invalid fixture: $fixture" >&2
    exit 1
  fi
  if ! printf '%s' "$err" | grep -Eq 'AstSpherepackError|unsupported|parse error|unexpected|invalid'; then
    echo "must-reject unexpected error for $fixture: $err" >&2
    exit 1
  fi
done

echo "ok ast-spherepack must-reject"
