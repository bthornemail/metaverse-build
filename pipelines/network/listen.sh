#!/usr/bin/env sh
set -euo pipefail

PORT="${PORT:-9000}"

nc -l "$PORT"
