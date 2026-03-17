#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACCEPT_DIR="$ROOT/runtime/tetragrammatron/fixtures/agent-memory/accept"
MR_DIR="$ROOT/runtime/tetragrammatron/fixtures/agent-memory/must-reject"
REPORT="$ROOT/reports/phase27I-agent-memory.json"
GOLDEN_HASH="$ROOT/golden/agent-memory/replay-hash"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

if [[ ! -d "$ACCEPT_DIR" ]]; then
  echo "missing accept fixture directory: $ACCEPT_DIR" >&2
  exit 2
fi
if [[ ! -f "$GOLDEN_HASH" ]]; then
  echo "missing golden hash: $GOLDEN_HASH" >&2
  exit 2
fi

mkdir -p "$(dirname "$REPORT")"

python3 - <<PY > "$TMP"
import json
from pathlib import Path
from runtime.tetragrammatron.io.agent_memory import (
  canonical_agent_memory_state,
  head_agent_sid,
  traverse_agent_memory,
  validate_agent_memory_state,
)

accept_dir = Path(r"$ACCEPT_DIR")
cases = []
for path in sorted(accept_dir.glob("*.json")):
  payload = json.loads(path.read_text(encoding="utf-8"))
  validate_agent_memory_state(payload)
  canonical = canonical_agent_memory_state(payload)
  head = head_agent_sid(payload)
  walk = traverse_agent_memory(payload, payload["frames"][0]["sid"], 10)
  cases.append(
    {
      "name": path.name,
      "head_sid": head,
      "frame_count": len(payload["frames"]),
      "traverse": walk,
      "canonical_sha256": "sha256:" + __import__("hashlib").sha256(canonical.encode("utf-8")).hexdigest(),
    }
  )

report = {
  "v": "phase27I.agent_memory_gate.v0",
  "authority": "advisory",
  "cases": cases,
}
print(json.dumps(report, sort_keys=True, separators=(",", ":"), ensure_ascii=False))
PY

cp "$TMP" "$REPORT"

want="$(tr -d '\n' < "$GOLDEN_HASH")"
got="sha256:$(sha256sum "$TMP" | awk '{print $1}')"
if [[ "$want" != "$got" ]]; then
  echo "agent-memory replay hash mismatch: expected $want got $got" >&2
  sed -n '1,160p' "$TMP" >&2
  exit 1
fi

for bad in "$MR_DIR"/*.json; do
  [[ -f "$bad" ]] || continue
  set +e
  err="$(python3 - <<PY 2>&1 >/dev/null
import json
from runtime.tetragrammatron.io.agent_memory import validate_agent_memory_state
payload = json.loads(open(r"$bad", "r", encoding="utf-8").read())
validate_agent_memory_state(payload)
raise SystemExit("accepted invalid fixture")
PY
)"
  status=$?
  set -e
  if [[ $status -eq 0 ]]; then
    echo "must-reject accepted invalid fixture: $bad" >&2
    exit 1
  fi
  if ! printf '%s' "$err" | grep -Eq 'AgentMemoryError|mismatch|invalid|unknown|duplicate|not found'; then
    echo "must-reject unexpected error for $bad: $err" >&2
    exit 1
  fi
done

echo "ok agent-memory gate"
