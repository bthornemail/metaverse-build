#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORLD_IR="${1:-}"

if [[ "$WORLD_IR" == "--world-ir" ]]; then
  WORLD_IR="${2:-}"
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

if [[ -z "$WORLD_IR" ]]; then
  MK="/home/main/devops/metaverse-kit"
  [[ -d "$MK" ]] || { echo "ERROR: metaverse-kit not found at $MK" >&2; exit 2; }
  WORLD_IR="$TMP_DIR/world.ir.json"
  node "$MK/tools/mv-runtime-handoff/index.js" build-world-ir-wave30 \
    --surface "$MK/dev-docs/wave30/evidence-surface.chords.v0.json" \
    --frames "$MK/dev-docs/wave30/evidence-surface.frames.leds240.v0.ndjson" \
    --emitter "$MK/dev-docs/wave30/evidence-surface.frames.leds240.esp32.v0.ndjson" \
    --uart "$MK/dev-docs/wave30/evidence-surface.uart.esp32.v0.ndjson" \
    --bundle "$MK/dev-docs/wave30/evidence-bundle.v0.json" \
    --wave31-receipt "$MK/dev-docs/wave31/golden/hardware-decode-receipt.v0.json" \
    --wave31-frame-verify "$MK/dev-docs/wave31/golden/frame-verify-result.v0.json" \
    --out "$WORLD_IR" \
    --world wave30-surface-v0 >/dev/null
fi

[[ -f "$WORLD_IR" ]] || { echo "ERROR: world.ir input not found: $WORLD_IR" >&2; exit 2; }

bash "$ROOT/runtime/world/load-ir.sh" "$WORLD_IR" >/dev/null

SNAP_A="$TMP_DIR/snapshot.a.json"
SNAP_B="$TMP_DIR/snapshot.b.json"
TRACE_A="$TMP_DIR/runtime.trace.a.ndjson"
TRACE_B="$TMP_DIR/runtime.trace.b.ndjson"
REPLAY_A="$TMP_DIR/replay.a.json"
REPLAY_B="$TMP_DIR/replay.b.json"

HASH_A="$(python3 "$ROOT/runtime/world/materialize.py" "$WORLD_IR" "$SNAP_A" "$TRACE_A")"
HASH_B="$(python3 "$ROOT/runtime/world/materialize.py" "$WORLD_IR" "$SNAP_B" "$TRACE_B")"
[[ "$HASH_A" == "$HASH_B" ]] || { echo "ERROR: materialize hash drift across reruns" >&2; exit 2; }
cmp -s "$SNAP_A" "$SNAP_B" || { echo "ERROR: runtime snapshot bytes drift across reruns" >&2; exit 2; }
cmp -s "$TRACE_A" "$TRACE_B" || { echo "ERROR: runtime trace bytes drift across reruns" >&2; exit 2; }

REPLAY_HASH_A="$(python3 "$ROOT/runtime/world/replay.py" "$TRACE_A" "$REPLAY_A")"
REPLAY_HASH_B="$(python3 "$ROOT/runtime/world/replay.py" "$TRACE_B" "$REPLAY_B")"
[[ "$HASH_A" == "$REPLAY_HASH_A" ]] || { echo "ERROR: replay mismatch for run A" >&2; exit 2; }
[[ "$HASH_B" == "$REPLAY_HASH_B" ]] || { echo "ERROR: replay mismatch for run B" >&2; exit 2; }

# Must-reject: malformed world.ir should fail schema layer.
BAD_IR="$TMP_DIR/bad.world.ir.json"
cat > "$BAD_IR" <<'JSON'
{"world":"bad","entities":{}}
JSON
set +e
BAD_OUT="$(bash "$ROOT/runtime/world/load-ir.sh" "$BAD_IR" 2>&1 >/dev/null)"
BAD_CODE=$?
set -e
if [[ $BAD_CODE -eq 0 ]]; then
  echo "ERROR: malformed world.ir did not fail schema validation" >&2
  exit 2
fi
grep -Fq "schema validation failed" <<<"$BAD_OUT" || {
  echo "ERROR: malformed world.ir missing schema reject marker" >&2
  echo "$BAD_OUT" >&2
  exit 2
}

echo "ok metaverse-build world.ir runtime replay closure"
