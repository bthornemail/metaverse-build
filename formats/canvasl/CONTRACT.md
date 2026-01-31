---
type: contract
capability: [[dev-vault/Capabilities/CanvasL|CanvasL]]
authority: bicf-production
status: frozen
---

# Contract: CanvasL

## Purpose
CanvasL execution engine.

## Inputs
- CanvasL JSONL records.

## Outputs
- Executed CanvasL actions.

## Invariants
- Conforms to CanvasL JSONL schema.

## Failure Modes
- No rendering or editor integration.

## Extraction Target
metaverse-build/formats/canvasl/

## Traceability
- [[dev-vault/Capabilities/CanvasL|CanvasL]]
- [[dev-vault/MOCs/Extraction-Plan]]
- [[dev-vault/MOCs/Capability-Evidence]]

## Unresolved Dependencies
- JSONL schema version alignment not finalized.
