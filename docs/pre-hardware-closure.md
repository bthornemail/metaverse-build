# Pre-Hardware Closure Gates

Host-only closure gates that must pass before hardware-in-loop lanes.

Canonical entrypoint:

- `bash scripts/check-pre-hardware-closure.sh`
- before hardware, run `check-pre-hardware-closure.sh`

Cross-repo binding extension (second patch, workspace root):

- `bash /home/main/devops/scripts/check-pre-hardware-closure-plus-ops-binding.sh`
- runs build-only closure, then `metaverse-kit` ops attestation contract binding

## Gates

- `bash scripts/check-pre-hardware-closure.sh`
  - Runs the strict metaverse-build 3-check closure:
    - `bash scripts/check-world-ir-runtime-replay.sh`
    - `bash scripts/check-federated-transport-equivalence.sh`
    - `bash scripts/check-ops-rollback-restore-drill.sh`
  - Fails closed on first error.
  - Success marker:
    - `ok metaverse-build pre-hardware closure`

- `bash scripts/check-federated-transport-equivalence.sh`
  - Runs transport/sync/replay closures:
    - `runtime/sync-transport/transport-tests.sh`
    - `runtime/sync-transport/chaos.sh`
    - `runtime/sync-world/simulate-two-peers.sh`
    - `scripts/check-world-ir-runtime-replay.sh`
    - `scripts/federated-transport-equivalence-must-reject.sh`
  - Emits:
    - `evidence/pre-hardware/transport-equivalence.attestation.v0.json`

- `bash scripts/check-ops-rollback-restore-drill.sh`
  - Runs rollback/restore drill closures:
    - `runtime/checkpoint/checkpoint-tests.sh`
    - `runtime/checkpoint/rolling-tests.sh`
    - `runtime/shards/shard-tests.sh`
    - `scripts/ops-rollback-restore-must-reject.sh`
  - Emits:
    - `evidence/pre-hardware/ops-rollback-restore-drill.attestation.v0.json`

## Attestation Contracts

Both attestation artifacts are host-side, advisory receipts:

- `v` is fixed by artifact type.
- `authority` is `advisory`.
- payload canonicalization is deterministic (`sort_keys`, compact separators, newline-inclusive digesting).
- `digest` is `sha256` of canonical payload without `digest`.

These artifacts are referenced by metaverse-kit operator docs:

- `docs/KEY_ROTATION.md`
- `docs/INCIDENT_RESPONSE.md`
