#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT="$ROOT/reports/phase27C-tetragrammatron.txt"
PASS_LINE="PASS: tetragrammatron FS->GS->RS->US roundtrip"

bash "$ROOT/runtime/world/lifecycle-tests.sh" >/dev/null

if [[ ! -f "$REPORT" ]]; then
  echo "missing report: $REPORT" >&2
  exit 1
fi

if ! grep -Fq "$PASS_LINE" "$REPORT"; then
  echo "tetragrammatron gate failed: pass marker missing in $REPORT" >&2
  sed -n '1,120p' "$REPORT" >&2
  exit 1
fi

bash "$ROOT/scripts/codepoint-synset-gate.sh" >/dev/null
bash "$ROOT/scripts/xml-projection-gate.sh" >/dev/null
bash "$ROOT/scripts/klein-gate.sh" >/dev/null
bash "$ROOT/scripts/ast-spherepack-gate.sh" >/dev/null
bash "$ROOT/scripts/light-garden-sphere-gate.sh" >/dev/null
bash "$ROOT/scripts/fano-scheduler-gate.sh" >/dev/null
bash "$ROOT/scripts/control-superposition-gate.sh" >/dev/null
bash "$ROOT/scripts/living-xml-gate.sh" >/dev/null
bash "$ROOT/scripts/agent-memory-gate.sh" >/dev/null
bash "$ROOT/scripts/identity-gate.sh" >/dev/null
bash "$ROOT/scripts/seed-algebra-gate.sh" >/dev/null
bash "$ROOT/scripts/lane16-gate.sh" >/dev/null

echo "ok tetragrammatron gate"
