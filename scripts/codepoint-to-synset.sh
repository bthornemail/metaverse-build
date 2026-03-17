#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INPUT="${1:-$ROOT/runtime/tetragrammatron/fixtures/codepoint-synset/golden/codepoints.txt}"
PREIMAGE_OUT="${2:-}"

AWK_SCRIPT="$ROOT/runtime/tetragrammatron/awk/codepoint-to-synset.awk"
UCD="$ROOT/runtime/tetragrammatron/fixtures/codepoint-synset/ucd.tsv"
CP_WORDS="$ROOT/runtime/tetragrammatron/fixtures/codepoint-synset/codepoint_words.tsv"
LEXICON="$ROOT/runtime/tetragrammatron/fixtures/codepoint-synset/lexicon.tsv"
FANO="$ROOT/runtime/tetragrammatron/fixtures/codepoint-synset/fano.tsv"

if [[ ! -f "$INPUT" ]]; then
  echo "missing input: $INPUT" >&2
  exit 2
fi

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

awk \
  -v ucd_path="$UCD" \
  -v cp_words_path="$CP_WORDS" \
  -v lexicon_path="$LEXICON" \
  -v fano_path="$FANO" \
  -f "$AWK_SCRIPT" \
  "$INPUT" > "$TMP"

if [[ -n "$PREIMAGE_OUT" ]]; then
  cp "$TMP" "$PREIMAGE_OUT"
fi

sha256sum "$TMP" | awk '{print "sha256:"$1}'
