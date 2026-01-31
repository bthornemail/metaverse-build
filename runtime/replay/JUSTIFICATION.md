---
type: justification
capability: [[dev-vault/Capabilities/Replay|Replay]]
authority: universal-life-protocol
status: frozen
---

# Capability Justification: Replay

## Purpose
Reconstruct execution from trace logs.

## Authority
universal-life-protocol provides explicit replay workflow (v1.1 decode).

## Inputs
- Trace logs.

## Outputs
- Reconstructed execution artifacts.

## Invariants
- Replayed output must match trace.

## Failure Modes
- Does not include UI or networking.

## Extraction Target
metaverse-build/runtime/replay/

## Traceability
- [[dev-vault/Capabilities/Replay|Replay]]
- [[dev-vault/Repos/universal-life-protocol|universal-life-protocol]]
- /home/main/devops/universal-life-protocol/README.md
