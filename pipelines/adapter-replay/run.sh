#!/usr/bin/env bash
# Capability: Replay
# Authority: bicf-production
# Justification: ../../runtime/replay/adapters/scheme/bicf-production/ADAPTER-JUSTIFICATION.md
# Inputs: validated payload (stdin)
# Outputs: projected replay payload (stdout)
# Trace: no
# Halt-On-Violation: yes

set -euo pipefail

# Projection-only replay adapter runner (no semantics, no authority)
cat
