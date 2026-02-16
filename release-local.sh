#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_NAME="$(basename "$REPO_DIR")"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
LABEL="${1:-$STAMP}"
OUT_ROOT="${OUT_ROOT:-$HOME/local-releases}"
OUT_DIR="$OUT_ROOT/$REPO_NAME"
BUNDLE_BASE="$REPO_NAME-$LABEL"

mkdir -p "$OUT_DIR"

TARBALL="$OUT_DIR/$BUNDLE_BASE.tar.gz"
SHA_FILE="$TARBALL.sha256"
MANIFEST="$OUT_DIR/$BUNDLE_BASE.manifest.txt"

# Archive current working tree (not only committed files).
tar \
  --exclude='.git' \
  --exclude='node_modules' \
  --exclude='*/node_modules' \
  --exclude='dist' \
  --exclude='*.tar.gz' \
  --exclude='*.zip' \
  -czf "$TARBALL" \
  -C "$(dirname "$REPO_DIR")" "$REPO_NAME"

sha256sum "$TARBALL" > "$SHA_FILE"

{
  echo "repo=$REPO_NAME"
  echo "label=$LABEL"
  echo "timestamp_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "tarball=$TARBALL"
  echo "sha256_file=$SHA_FILE"
  if git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "git_commit=$(git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
    echo "git_branch=$(git -C "$REPO_DIR" branch --show-current 2>/dev/null || echo detached)"
    echo "git_dirty=$(test -n "$(git -C "$REPO_DIR" status --porcelain 2>/dev/null)" && echo true || echo false)"
  fi
} > "$MANIFEST"

# Optional local tag: TAG_LOCAL=1 ./release-local.sh v0.2-local
if [[ "${TAG_LOCAL:-0}" == "1" ]] && git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if [[ -z "$(git -C "$REPO_DIR" status --porcelain 2>/dev/null)" ]]; then
    git -C "$REPO_DIR" tag -a "$LABEL" -m "local release $LABEL"
    echo "local git tag created: $LABEL"
  else
    echo "skip tag: repo has uncommitted changes"
  fi
fi

echo "created: $TARBALL"
echo "sha256:  $SHA_FILE"
echo "manifest:$MANIFEST"
