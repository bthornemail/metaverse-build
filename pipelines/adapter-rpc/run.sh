#!/usr/bin/env bash
# Capability: RPC
# Authority: automata-metaverse
# Justification: ../../runtime/rpc/adapters/typescript/automata-metaverse/ADAPTER-JUSTIFICATION.md
# Inputs: validated payload (stdin)
# Outputs: projected RPC payload (stdout)
# Trace: no
# Halt-On-Violation: yes

set -euo pipefail

# Projection-only RPC adapter runner (no semantics, no authority)
cat
