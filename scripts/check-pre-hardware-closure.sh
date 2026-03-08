#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

bash scripts/check-world-ir-runtime-replay.sh
bash scripts/check-federated-transport-equivalence.sh
bash scripts/check-ops-rollback-restore-drill.sh

echo "ok metaverse-build pre-hardware closure"
