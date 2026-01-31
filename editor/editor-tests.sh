#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPORT="$ROOT/reports/phase28-editor.txt"

IR="$ROOT/world-ir/build/room.ir.json"
SNAP_DIR="$ROOT/runtime/world/snapshots"
TRACE_DIR="$ROOT/runtime/world/trace"

mkdir -p "$SNAP_DIR" "$TRACE_DIR" "$ROOT/reports"

# Ensure base snapshot exists
bash "$ROOT/runtime/world/load-ir.sh" "$IR" >/dev/null

BASE_SNAPSHOT="$SNAP_DIR/room.snapshot.json"
EDITOR_SNAPSHOT="$SNAP_DIR/room.editor.test.snapshot.json"
EDITOR_TRACE="$TRACE_DIR/room.editor.test.jsonl"

rm -f "$EDITOR_SNAPSHOT" "$EDITOR_TRACE"

ACTOR=valid:userA EDITOR_SNAPSHOT="$EDITOR_SNAPSHOT" EDITOR_TRACE="$EDITOR_TRACE" \
  bash "$ROOT/editor/world-edit.sh" create test-actor

ACTOR=valid:userA EDITOR_SNAPSHOT="$EDITOR_SNAPSHOT" EDITOR_TRACE="$EDITOR_TRACE" \
  bash "$ROOT/editor/world-edit.sh" attach test-actor tag --data '{"label":"ok"}'

hash_editor=$(python3 - <<PY
import hashlib,sys
print(hashlib.sha256(open("$EDITOR_SNAPSHOT","rb").read()).hexdigest())
PY
)

hash_replay=$(python3 "$ROOT/runtime/world/apply-event.py" "$BASE_SNAPSHOT" "$EDITOR_TRACE" "$SNAP_DIR/room.editor.replay.json")

# FAIL authority: actor mismatch
hash_before_fail=$(python3 - <<PY
import hashlib,sys
print(hashlib.sha256(open("$EDITOR_SNAPSHOT","rb").read()).hexdigest())
PY
)

set +e
ACTOR=valid:userB EDITOR_SNAPSHOT="$EDITOR_SNAPSHOT" EDITOR_TRACE="$EDITOR_TRACE" \
  bash "$ROOT/editor/world-edit.sh" update test-actor tag --patch '{"label":"nope"}' 2>"$TRACE_DIR/editor.fail.stderr"
fail_status=$?
set -e

hash_after_fail=$(python3 - <<PY
import hashlib,sys
print(hashlib.sha256(open("$EDITOR_SNAPSHOT","rb").read()).hexdigest())
PY
)

{
  echo "# Phase 28 — Editor Surface"
  echo "Date: $(date -Iseconds)"
  echo "IR: $IR"
  echo "Base Snapshot: $BASE_SNAPSHOT"
  echo "Editor Snapshot: $EDITOR_SNAPSHOT"
  echo "Editor Trace: $EDITOR_TRACE"
  echo "Hash Editor: $hash_editor"
  echo "Hash Replay: $hash_replay"
  if [ "$hash_editor" = "$hash_replay" ]; then
    echo "PASS: editor determinism"
  else
    echo "FAIL: editor determinism"
  fi
  echo "Fail Status: $fail_status"
  echo "Fail Stderr: $(cat "$TRACE_DIR/editor.fail.stderr" 2>/dev/null || true)"
  echo "Hash Before Fail: $hash_before_fail"
  echo "Hash After Fail: $hash_after_fail"
  if [ "$fail_status" -ne 0 ] && [ "$hash_before_fail" = "$hash_after_fail" ]; then
    echo "PASS: authority HALT preserves snapshot"
  else
    echo "FAIL: authority HALT did not preserve snapshot"
  fi
} > "$REPORT"

sed -n '1,200p' "$REPORT"

if [ "$hash_editor" != "$hash_replay" ]; then
  exit 1
fi

if [ "$fail_status" -eq 0 ] || [ "$hash_before_fail" != "$hash_after_fail" ]; then
  exit 1
fi
