#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REPORT="$ROOT/reports/phase24-transcript.txt"

{
  echo "# Phase 24 — mind-git Projection Transcript"
  echo "Date: $(date -Iseconds)"
  echo "Host: $(hostname)"
  echo

  echo "## Ingest"
  bash "$ROOT/pipelines/mind-git/ingest.sh"
  echo

  echo "## Canvas"
  python3 "$ROOT/pipelines/mind-git/render-canvas.py"
  echo

  echo "## Report"
  python3 "$ROOT/pipelines/mind-git/report.py"
} > "$REPORT"

sed -n '1,200p' "$REPORT"
