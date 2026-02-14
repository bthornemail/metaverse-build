#!/usr/bin/env bash
set -euo pipefail

# Convenience wrapper for local monorepo usage:
# build-report.json -> seam envelopes -> append into a port-matroid store dir.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PM_ROOT="${PM_ROOT:-$ROOT/../port-matroid}"

if [ $# -ne 2 ]; then
  echo "usage: append-to-port-matroid.sh <build-report.json> <port-matroid-store-dir>" >&2
  exit 2
fi

inp="$1"
store="$2"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

python3 "$ROOT/scripts/emit-seam-envelopes.py" --input "$inp" >"$tmp"

(cd "$PM_ROOT" && cabal -v0 run port-matroid-tool -- append-envelope "$store" "$tmp")

