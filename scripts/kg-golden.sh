#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GRAMMAR_DIR="$ROOT/runtime/tetragrammatron/grammars"
GEN_DIR="$ROOT/runtime/tetragrammatron/generated/ast_spherepack"
TMP_OUT="$(mktemp)"
TMP_INDEX="$(mktemp)"
trap 'rm -f "$TMP_OUT" "$TMP_INDEX"' EXIT

for lang in python javascript; do
  grammar="$GRAMMAR_DIR/$lang.kg"
  generated="$GEN_DIR/$lang.mapping.json"
  python3 "$ROOT/runtime/tetragrammatron/tools/kgc.py" "$grammar" > "$TMP_OUT"
  if ! cmp -s "$TMP_OUT" "$generated"; then
    echo "kg mapping mismatch for $lang" >&2
    echo "--- generated ---" >&2
    sed -n '1,120p' "$TMP_OUT" >&2
    echo "--- expected ---" >&2
    sed -n '1,120p' "$generated" >&2
    exit 1
  fi
done

{
  sha256sum "$GEN_DIR/python.mapping.json"
  sha256sum "$GEN_DIR/javascript.mapping.json"
} | awk '{print $1}' > "$TMP_INDEX"

want="$(tr -d '\n' < "$ROOT/golden/ast-spherepack/kg.replay-hash")"
got="sha256:$(sha256sum "$TMP_INDEX" | awk '{print $1}')"
if [[ "$want" != "$got" ]]; then
  echo "kg replay hash mismatch: expected $want got $got" >&2
  exit 1
fi

echo "ok kg golden"
