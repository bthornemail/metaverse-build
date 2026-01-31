#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CMD="${1:-}"

if [ -z "$CMD" ]; then
  echo "usage: world-edit.sh <create|destroy|attach|update|detach|move> [args...]" >&2
  exit 2
fi

ACTOR="${ACTOR:-}"
if [ -z "$ACTOR" ]; then
  echo "ACTOR is required" >&2
  exit 2
fi

WORLD_IR="${WORLD_IR:-$ROOT/world-ir/build/room.ir.json}"
TRACE_DIR="$ROOT/runtime/world/trace"
SNAP_DIR="$ROOT/runtime/world/snapshots"

mkdir -p "$TRACE_DIR" "$SNAP_DIR"

BASE_SNAPSHOT="$SNAP_DIR/room.snapshot.json"
if [ ! -f "$BASE_SNAPSHOT" ]; then
  bash "$ROOT/runtime/world/load-ir.sh" "$WORLD_IR" >/dev/null
fi

CURRENT_SNAPSHOT="${EDITOR_SNAPSHOT:-$SNAP_DIR/room.editor.snapshot.json}"
TRACE_LOG="${EDITOR_TRACE:-$TRACE_DIR/room.editor.jsonl}"

if [ ! -f "$CURRENT_SNAPSHOT" ]; then
  cp "$BASE_SNAPSHOT" "$CURRENT_SNAPSHOT"
fi

TMP_EVENT="$TRACE_DIR/.tmp.event.jsonl"
TMP_SNAPSHOT="$SNAP_DIR/.tmp.editor.snapshot.json"

python3 "$ROOT/editor/intent-to-event.py" "$@" --actor "$ACTOR" > "$TMP_EVENT"
cat "$TMP_EVENT" >> "$TRACE_LOG"

set +e
hash=$(python3 "$ROOT/runtime/world/apply-event.py" "$CURRENT_SNAPSHOT" "$TMP_EVENT" "$TMP_SNAPSHOT" 2>"$TRACE_DIR/.tmp.editor.stderr")
status=$?
set -e

if [ "$status" -ne 0 ]; then
  cat "$TRACE_DIR/.tmp.editor.stderr" >&2
  rm -f "$TMP_SNAPSHOT" "$TMP_EVENT" "$TRACE_DIR/.tmp.editor.stderr"
  exit "$status"
fi

mv "$TMP_SNAPSHOT" "$CURRENT_SNAPSHOT"
rm -f "$TMP_EVENT" "$TRACE_DIR/.tmp.editor.stderr"

printf '%s\n' "$hash"
