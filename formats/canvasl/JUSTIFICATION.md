---
type: justification
capability: [[dev-vault/Capabilities/CanvasL|CanvasL]]
authority: bicf-production
status: frozen
---

# Capability Justification: CanvasL

## Purpose
Execute CanvasL programs and validate CanvasL semantics.

## Authority
bicf-production provides the CanvasL interpreter.

## Inputs
- CanvasL JSONL records.

## Outputs
- Executed CanvasL actions.

## Invariants
- Interpreter follows CanvasL schema.

## Failure Modes
- Does not define UI or visualization.

## Extraction Target
metaverse-build/formats/canvasl/

## Traceability
- [[dev-vault/Capabilities/CanvasL|CanvasL]]
- [[dev-vault/Repos/bicf-production|bicf-production]]
- /home/main/devops/bicf-production/README.md
