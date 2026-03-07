#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

DOC="docs/LAYER_CONTRACT_RUNTIME_HOST_METAVERSE_BUILD.md"
[[ -f "$DOC" ]] || { echo "ERROR: missing runtime host layer contract: $DOC" >&2; exit 2; }

require_literal() {
  local file="$1"
  local lit="$2"
  grep -Fq -- "$lit" "$file" || { echo "ERROR: missing literal in $file: $lit" >&2; exit 2; }
}

require_literal "$DOC" '- Layer: hypervisor'
require_literal "$DOC" '- Authority class: advisory'
require_literal "$DOC" '- Name: `metaverse-build runtime host`'
require_literal "$DOC" "## Forbidden Behavior"
require_literal "$DOC" 'Must not bypass authority gate before emission.'
require_literal "$DOC" 'Must not reinterpret wave artifact semantics.'

if rg -n 'Alternative implementations may be used|implementation-defined|may vary' "$DOC" >/dev/null; then
  echo "ERROR: ambiguous wording found in runtime host contract" >&2
  exit 2
fi

echo "ok runtime host layer contract guard"
