#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GOLDEN_INPUT="$ROOT/runtime/tetragrammatron/fixtures/codepoint-synset/golden/codepoints.txt"
MUST_REJECT_INPUT="$ROOT/runtime/tetragrammatron/fixtures/codepoint-synset/must-reject/unknown-codepoint.txt"
GOLDEN_HASH_FILE="$ROOT/golden/codepoint-synset/replay-hash"

if [[ ! -f "$GOLDEN_HASH_FILE" ]]; then
  echo "missing golden hash: $GOLDEN_HASH_FILE" >&2
  exit 2
fi

want="$(tr -d '\n' < "$GOLDEN_HASH_FILE")"
got1="$(bash "$ROOT/scripts/codepoint-to-synset.sh" "$GOLDEN_INPUT")"
got2="$(bash "$ROOT/scripts/codepoint-to-synset.sh" "$GOLDEN_INPUT")"

if [[ "$got1" != "$got2" ]]; then
  echo "codepoint->synset nondeterministic digest: $got1 != $got2" >&2
  exit 1
fi

if [[ "$got1" != "$want" ]]; then
  echo "codepoint->synset golden mismatch: expected $want got $got1" >&2
  exit 1
fi

set +e
err="$(bash "$ROOT/scripts/codepoint-to-synset.sh" "$MUST_REJECT_INPUT" 2>&1 >/dev/null)"
status=$?
set -e
if [[ $status -eq 0 ]]; then
  echo "must-reject accepted unknown codepoint" >&2
  exit 1
fi
if ! printf '%s' "$err" | grep -q "unknown codepoint"; then
  echo "must-reject wrong error: $err" >&2
  exit 1
fi

echo "ok codepoint->synset gate"
