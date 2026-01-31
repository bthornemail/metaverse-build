#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BASE_SNAPSHOT="${1:-}"
MERGED_LOG="${2:-}"
OUT_SNAPSHOT="${3:-}"
HALT_LOG="${4:-$ROOT/runtime/sync-world/state/halts.log}"

if [ -z "$BASE_SNAPSHOT" ] || [ -z "$MERGED_LOG" ] || [ -z "$OUT_SNAPSHOT" ]; then
  echo "usage: apply-merged.sh <base_snapshot> <merged_log> <out_snapshot> [halt_log]" >&2
  exit 2
fi

STATE_DIR="$ROOT/runtime/sync-world/state"
TMP_DIR="$STATE_DIR/tmp"
mkdir -p "$STATE_DIR" "$TMP_DIR"

cp "$BASE_SNAPSHOT" "$OUT_SNAPSHOT"
: > "$HALT_LOG"

i=0
while IFS= read -r line; do
  [ -z "$line" ] && continue
  i=$((i+1))
  event_file="$TMP_DIR/event.$i.jsonl"
  python3 - <<PY > "$event_file"
import json
env = json.loads('''$line''')
ev = env.get('event', {})
print(json.dumps(ev, separators=(",", ":")))
PY

  set +e
  hash=$(python3 "$ROOT/runtime/world/apply-event.py" "$OUT_SNAPSHOT" "$event_file" "$TMP_DIR/out.$i.json" 2>"$TMP_DIR/err.$i")
  status=$?
  set -e

  if [ "$status" -eq 0 ]; then
    mv "$TMP_DIR/out.$i.json" "$OUT_SNAPSHOT"
  elif [ "$status" -eq 3 ]; then
    msg=$(cat "$TMP_DIR/err.$i" 2>/dev/null || true)
    echo "HALT $i $msg" >> "$HALT_LOG"
  else
    cat "$TMP_DIR/err.$i" >&2
    exit "$status"
  fi

done < "$MERGED_LOG"

python3 - <<PY
import hashlib
with open("$OUT_SNAPSHOT","rb") as fh:
    print(hashlib.sha256(fh.read()).hexdigest())
PY
