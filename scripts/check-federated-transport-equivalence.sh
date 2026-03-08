#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

ATTEST_DIR="$ROOT/evidence/pre-hardware"
ATTEST="$ATTEST_DIR/transport-equivalence.attestation.v0.json"
mkdir -p "$ATTEST_DIR"

sha256_file() {
  local p="$1"
  [[ -f "$p" ]] || { echo ""; return 0; }
  sha256sum "$p" | awk '{print "sha256:"$1}'
}

run_transport_tests() {
  local d="$TMP_DIR/transport-tests"
  mkdir -p "$d"
  STATE_DIR="$d/state" \
  BUS_FIFO="$d/state/bus.fifo" \
  LOG_DIR="$d/logs" \
  MERGED_LOG="$d/merged.jsonl" \
  REPORT="$d/phase30A-transport.txt" \
    bash "$ROOT/runtime/sync-transport/transport-tests.sh" >/dev/null
  python3 "$ROOT/scripts/validate-transport-envelope-sequence.py" "$d/logs/received.jsonl" >/dev/null
  echo "$(sha256_file "$d/state/peerA.snapshot.json")|$(sha256_file "$d/state/peerB.snapshot.json")|$(sha256_file "$d/merged.jsonl")|$(sha256_file "$d/state/peerA.halts.log")"
}

run_chaos_tests() {
  local d="$TMP_DIR/chaos"
  mkdir -p "$d"
  STATE_DIR="$d/state" \
  LOG_DIR="$d/logs" \
  MERGED_LOG="$d/merged.jsonl" \
  REPORT="$d/phase30A1-chaos.txt" \
    bash "$ROOT/runtime/sync-transport/chaos.sh" >/dev/null
  echo "$(sha256_file "$d/state/peerA.snapshot.json")|$(sha256_file "$d/state/peerB.snapshot.json")|$(sha256_file "$d/merged.jsonl")|$(sha256_file "$d/state/peerA.halts.log")"
}

run_simulation_tests() {
  local d="$TMP_DIR/sim"
  mkdir -p "$d"
  STATE_DIR="$d/state" \
  LOG_DIR="$d/state/logs" \
  MERGED_LOG="$d/state/merged.jsonl" \
  REPORT="$d/phase29-sync.txt" \
    bash "$ROOT/runtime/sync-world/simulate-two-peers.sh" >/dev/null
  echo "$(sha256_file "$d/state/peerA.snapshot.json")|$(sha256_file "$d/state/peerB.snapshot.json")|$(sha256_file "$d/state/merged.jsonl")|$(sha256_file "$d/state/peerA.halts.log")"
}

TRANS_A="$TMP_DIR/transport.a.out"
TRANS_B="$TMP_DIR/transport.b.out"
CHAOS_A="$TMP_DIR/chaos.a.out"
CHAOS_B="$TMP_DIR/chaos.b.out"
SIM_A="$TMP_DIR/sim.a.out"
SIM_B="$TMP_DIR/sim.b.out"

run_transport_tests >"$TRANS_A"
run_transport_tests >"$TRANS_B"
cmp -s "$TRANS_A" "$TRANS_B" || { echo "ERROR: transport-tests non-deterministic across reruns" >&2; exit 2; }
TRANSPORT_DIGESTS="$(cat "$TRANS_A")"

run_chaos_tests >"$CHAOS_A"
run_chaos_tests >"$CHAOS_B"
cmp -s "$CHAOS_A" "$CHAOS_B" || { echo "ERROR: chaos-tests non-deterministic across reruns" >&2; exit 2; }
CHAOS_DIGESTS="$(cat "$CHAOS_A")"

run_simulation_tests >"$SIM_A"
run_simulation_tests >"$SIM_B"
cmp -s "$SIM_A" "$SIM_B" || { echo "ERROR: simulate-two-peers non-deterministic across reruns" >&2; exit 2; }
SIM_DIGESTS="$(cat "$SIM_A")"

bash "$ROOT/scripts/check-world-ir-runtime-replay.sh" >/dev/null
bash "$ROOT/scripts/federated-transport-equivalence-must-reject.sh" >/dev/null

WORLD_IR="$ROOT/world-ir/build/room.ir.json"
python3 "$ROOT/runtime/world/materialize.py" "$WORLD_IR" "$TMP_DIR/replay.snapshot.json" "$TMP_DIR/replay.trace.ndjson" >/dev/null
python3 "$ROOT/runtime/world/replay.py" "$TMP_DIR/replay.trace.ndjson" "$TMP_DIR/replay.reconstructed.snapshot.json" >/dev/null
WORLD_IR_DIGEST="$(python3 - <<PY
import json,hashlib
obj=json.load(open("$WORLD_IR"))
print("sha256:"+hashlib.sha256((json.dumps(obj,sort_keys=True,separators=(",",":"))+"\\n").encode()).hexdigest())
PY
)"

python3 - <<PY > "$ATTEST"
import json,hashlib

def canon(v):
    return json.dumps(v, sort_keys=True, separators=(",", ":"))

att = {
  "v": "metaverse-build.transport_equivalence_attestation.v0",
  "authority": "advisory",
  "deterministic": "1",
  "checks": [
    "transport-tests",
    "chaos-tests",
    "simulate-two-peers",
    "world-ir-runtime-replay",
    "must-reject-corpus"
  ],
  "fail_classes": [
    "peer_divergence",
    "authority_rejection_state_mutation",
    "transport_envelope_sequence_violation",
    "replay_equivalence_drift"
  ],
  "artifacts": {
    "transport_tests_digests": "$TRANSPORT_DIGESTS",
    "chaos_tests_digests": "$CHAOS_DIGESTS",
    "simulate_two_peers_digests": "$SIM_DIGESTS",
    "world_ir_digest": "$WORLD_IR_DIGEST",
    "runtime_trace_digest": "$(sha256_file "$TMP_DIR/replay.trace.ndjson")",
    "runtime_snapshot_digest": "$(sha256_file "$TMP_DIR/replay.snapshot.json")",
    "replay_snapshot_digest": "$(sha256_file "$TMP_DIR/replay.reconstructed.snapshot.json")"
  }
}
payload = dict(att)
att["digest"] = "sha256:" + hashlib.sha256((canon(payload) + "\n").encode("utf-8")).hexdigest()
print(canon(att))
PY

echo "ok metaverse-build federated transport equivalence closure attestation=$ATTEST"
