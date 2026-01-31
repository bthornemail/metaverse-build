#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REPORT="$ROOT/reports/phase24G-transcript.txt"

{
  echo "# Phase 24G — Vault Snapshot Export"
  echo "Date: $(date -Iseconds)"
  echo "Host: $(hostname)"
  echo

  echo "## Export"
  python3 "$ROOT/pipelines/mind-git/export-vault.py"
} > "$REPORT"

sed -n '1,200p' "$REPORT"
