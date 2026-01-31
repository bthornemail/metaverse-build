#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

bash "$ROOT/runtime/lattice/compiler/graph-basis-compiler.sh"
bash "$ROOT/runtime/lattice/compiler/plan-projector.sh"
