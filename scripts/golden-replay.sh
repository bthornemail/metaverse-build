#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PM_ROOT="${PM_ROOT:-$ROOT/../port-matroid}"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

check_one() {
  local fixture="$1"
  local want_file="$2"
  local fixture_perm="$3"

  if [ ! -f "$want_file" ]; then
    echo "missing expected hash file: $want_file" >&2
    exit 2
  fi
  local want
  want="$(tr -d '\n' <"$want_file")"

  local store="$tmpdir/pm-store-$(basename "$want_file")"
  "$ROOT/scripts/append-to-port-matroid.sh" "$fixture" "$store" >/dev/null
  (cd "$PM_ROOT" && cabal -v0 run port-matroid-tool -- audit "$store" >/dev/null)
  local got
  got="$(cd "$PM_ROOT" && cabal -v0 run port-matroid-tool -- replay-hash "$store" | tr -d '\n')"
  if [ "$got" != "$want" ]; then
    echo "golden replay hash mismatch ($fixture): expected $want got $got" >&2
    exit 1
  fi

  # Ordering invariance: permuted input must yield the same replay hash.
  local store2="$tmpdir/pm-store-perm-$(basename "$want_file")"
  "$ROOT/scripts/append-to-port-matroid.sh" "$fixture_perm" "$store2" >/dev/null
  (cd "$PM_ROOT" && cabal -v0 run port-matroid-tool -- audit "$store2" >/dev/null)
  local got2
  got2="$(cd "$PM_ROOT" && cabal -v0 run port-matroid-tool -- replay-hash "$store2" | tr -d '\n')"
  if [ "$got2" != "$want" ]; then
    echo "permuted fixture replay hash mismatch ($fixture_perm): expected $want got $got2" >&2
    exit 1
  fi
}

if [ "$#" -gt 0 ]; then
  fixture="$1"
  want_file="$2"
  fixture_perm="$3"
  check_one "$fixture" "$want_file" "$fixture_perm"
  echo "ok metaverse-build golden replay hash"
  exit 0
fi

check_one \
  "$ROOT/golden/ulp-producer/mini.input.json" \
  "$ROOT/golden/ulp-producer/mini.replay-hash" \
  "$ROOT/golden/ulp-producer/mini.permuted.input.json"

check_one \
  "$ROOT/golden/ulp-producer/multi.input.json" \
  "$ROOT/golden/ulp-producer/multi.replay-hash" \
  "$ROOT/golden/ulp-producer/multi.permuted.input.json"

check_one \
  "$ROOT/golden/ulp-producer/failure.input.json" \
  "$ROOT/golden/ulp-producer/failure.replay-hash" \
  "$ROOT/golden/ulp-producer/failure.permuted.input.json"

echo "ok metaverse-build golden replay hashes"
