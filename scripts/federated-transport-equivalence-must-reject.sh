#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MR_DIR="$ROOT/evidence/pre-hardware/must-reject"
VALIDATOR="$ROOT/scripts/validate-transport-envelope-sequence.py"

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

expect_fail "reordered transport envelopes" "non-contiguous seq" \
  python3 "$VALIDATOR" "$MR_DIR/transport-reordered.ndjson"

expect_fail "duplicate transport envelopes" "duplicate peer/seq" \
  python3 "$VALIDATOR" "$MR_DIR/transport-duplicate.ndjson"

expect_fail "missing seq in transport envelope" "envelope keyset mismatch" \
  python3 "$VALIDATOR" "$MR_DIR/transport-missing-seq.ndjson"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
IR="$ROOT/world-ir/build/room.ir.json"
SNAP="$TMP_DIR/replay-drift.snapshot.json"
TRACE="$TMP_DIR/replay-drift.trace.ndjson"

python3 "$ROOT/runtime/world/materialize.py" "$IR" "$SNAP" "$TRACE" >/dev/null
echo '{"type":"UNKNOWN_DRIFT_EVENT"}' >> "$TRACE"
expect_fail "replay drift injection" "unknown event type" \
  python3 "$ROOT/runtime/world/replay.py" "$TRACE" "$TMP_DIR/replay-drift.replay.json"

echo "ok federated transport equivalence must-reject"
