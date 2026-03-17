#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

ATTEST_DIR="$ROOT/evidence/pre-hardware"
ATTEST="$ATTEST_DIR/ops-rollback-restore-drill.attestation.v0.json"
TRANSPORT_ATTEST="$ATTEST_DIR/transport-equivalence.attestation.v0.json"
mkdir -p "$ATTEST_DIR"

sha256_file() {
  local p="$1"
  [[ -f "$p" ]] || { echo ""; return 0; }
  sha256sum "$p" | awk '{print "sha256:"$1}'
}

[[ -f "$TRANSPORT_ATTEST" ]] || {
  echo "ERROR: missing linked transport attestation: $TRANSPORT_ATTEST" >&2
  exit 2
}

run_checkpoint_suite() {
  local d="$TMP_DIR/checkpoint"
  mkdir -p "$d"
  STATE_DIR="$d/state" REPORT="$d/phase33A-checkpoint.txt" \
    bash "$ROOT/runtime/checkpoint/checkpoint-tests.sh" >/dev/null
  echo "$(sha256_file "$d/state/zone.restored.json")|$(sha256_file "$d/state/zone.expected.json")|$(sha256_file "$d/state/zone.trace.full.jsonl")"
}

run_rolling_suite() {
  local d="$TMP_DIR/rolling"
  mkdir -p "$d"
  STATE_DIR="$d/state" REPORT="$d/phase33B-rolling.txt" \
    bash "$ROOT/runtime/checkpoint/rolling-tests.sh" >/dev/null
  echo "$(sha256_file "$d/state/full.snapshot.json")|$(sha256_file "$d/state/window.snapshot.json")|$(sha256_file "$d/state/rolling.trace.jsonl")"
}

run_shard_suite() {
  local d="$TMP_DIR/shards"
  mkdir -p "$d"
  STATE_DIR="$d/state" REPORT="$d/phase34-shards.txt" \
    bash "$ROOT/runtime/shards/shard-tests.sh" >/dev/null
  echo "$(sha256_file "$d/state/zone.snapshot.json")|$(sha256_file "$d/state/zone.trace.jsonl")|$(sha256_file "$d/state/nodeB/zone-a/zone.snapshot.json")"
}

CK_A="$TMP_DIR/ck.a.out"; CK_B="$TMP_DIR/ck.b.out"
RL_A="$TMP_DIR/rl.a.out"; RL_B="$TMP_DIR/rl.b.out"
SH_A="$TMP_DIR/sh.a.out"; SH_B="$TMP_DIR/sh.b.out"

run_checkpoint_suite >"$CK_A"
run_checkpoint_suite >"$CK_B"
cmp -s "$CK_A" "$CK_B" || { echo "ERROR: checkpoint drill non-deterministic across reruns" >&2; exit 2; }
CHECKPOINT_DIGESTS="$(cat "$CK_A")"

run_rolling_suite >"$RL_A"
run_rolling_suite >"$RL_B"
cmp -s "$RL_A" "$RL_B" || { echo "ERROR: rolling drill non-deterministic across reruns" >&2; exit 2; }
ROLLING_DIGESTS="$(cat "$RL_A")"

run_shard_suite >"$SH_A"
run_shard_suite >"$SH_B"
cmp -s "$SH_A" "$SH_B" || { echo "ERROR: shard drill non-deterministic across reruns" >&2; exit 2; }
SHARD_DIGESTS="$(cat "$SH_A")"

bash "$ROOT/scripts/ops-rollback-restore-must-reject.sh" >/dev/null

RUNTIME_CONFORMANCE="$ROOT/runtime/world/trace/room.runtime.conformance.json"
if [[ ! -f "$RUNTIME_CONFORMANCE" ]]; then
  IR_INPUT="$ROOT/world-ir/build/room.ir.json"
  if [[ ! -f "$IR_INPUT" ]]; then
    IR_INPUT="$ROOT/world-ir/examples/room-with-entity.json"
  fi
  bash "$ROOT/runtime/world/load-ir.sh" "$IR_INPUT" >/dev/null
fi

python3 - <<PY > "$ATTEST"
import json,hashlib

def canon(v):
    return json.dumps(v, sort_keys=True, separators=(",", ":"))

att = {
  "v": "metaverse-build.ops_rollback_restore_drill_attestation.v0",
  "authority": "advisory",
  "deterministic": "1",
  "drills": {
    "checkpoint_restore": "1",
    "rolling_checkpoint": "1",
    "shard_restore": "1",
    "must_reject": "1"
  },
  "fail_classes": [
    "restore_mismatch",
    "checkpoint_hash_mismatch",
    "shard_manifest_mismatch"
  ],
  "linked_attestations": {
    "transport_equivalence_digest": "$(sha256_file "$TRANSPORT_ATTEST")",
    "runtime_conformance_digest": "$(sha256_file "$RUNTIME_CONFORMANCE")"
  },
  "artifacts": {
    "checkpoint_drill_digests": "$CHECKPOINT_DIGESTS",
    "rolling_drill_digests": "$ROLLING_DIGESTS",
    "shard_drill_digests": "$SHARD_DIGESTS"
  }
}
payload = dict(att)
att["digest"] = "sha256:" + hashlib.sha256((canon(payload) + "\n").encode("utf-8")).hexdigest()
print(canon(att))
PY

echo "ok metaverse-build ops rollback/restore drill closure attestation=$ATTEST"
