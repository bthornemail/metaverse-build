---
type: contract
capability: [[dev-vault/Capabilities/Replay|Replay]]
authority: universal-life-protocol
status: frozen
---

# Contract: Replay

## Purpose
Deterministic replay from trace logs.

## Inputs
- Trace logs.

## Outputs
- Reconstructed artifacts.

## Invariants
- Replay must reproduce trace outputs.

## Failure Modes
- Does not define log storage (handled by Immutable-Log).

## Extraction Target
metaverse-build/runtime/replay/

## Traceability
- [[dev-vault/Capabilities/Replay|Replay]]
- [[dev-vault/MOCs/Extraction-Plan]]
- [[dev-vault/MOCs/Capability-Evidence]]

## Unresolved Dependencies
- Trace format alignment with Immutable-Log not defined yet.
