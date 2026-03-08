#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MR_DIR="$ROOT/evidence/pre-hardware/must-reject"

expect_fail() {
  local label="$1"
  local needle="$2"
  shift 2
  set +e
  local out
  out="$($@ 2>&1)"
  local code=$?
  set -e
  if [[ $code -eq 0 ]]; then
    echo "ERROR: expected failure for $label" >&2
    exit 2
  fi
  grep -Fq -- "$needle" <<<"$out" || {
    echo "ERROR: missing reject marker for $label: $needle" >&2
    echo "$out" >&2
    exit 2
  }
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
SHARD_STATE_DIR="$TMP_DIR/shards-state"

expect_fail "checkpoint missing snapshot ref" "invalid checkpoint: missing fields" \
  python3 "$ROOT/runtime/checkpoint/restore.py" "$MR_DIR/checkpoint-missing-snapshot.json" "$TMP_DIR/out.snapshot.json"

# Build a valid shard, then tamper checkpoint hash in manifest.
STATE_DIR="$SHARD_STATE_DIR" REPORT="$TMP_DIR/phase34-shards.txt" \
  bash "$ROOT/runtime/shards/shard-tests.sh" >/dev/null

cp -r "$SHARD_STATE_DIR/nodeA/zone-a" "$TMP_DIR/zone-a-bad"
python3 - <<PY
import json
p="$TMP_DIR/zone-a-bad/manifest.json"
m=json.load(open(p))
m["checkpoint_hash"]="sha256:0000000000000000000000000000000000000000000000000000000000000000"
open(p,"w").write(json.dumps(m,sort_keys=True,separators=(",",":")))
PY

expect_fail "shard checkpoint hash mismatch" "HALT: checkpoint hash mismatch" \
  python3 "$ROOT/runtime/shards/restore.py" "$TMP_DIR/zone-a-bad"

echo "ok ops rollback/restore must-reject"
