---
type: contract
capability: [[dev-vault/Capabilities/JSONL|JSONL]]
authority: bicf-production
status: frozen
---

# Contract: JSONL

## Purpose
JSONL schema for CanvasL records.

## Inputs
- JSONL records.

## Outputs
- Schema validation.

## Invariants
- Schema must remain stable.

## Failure Modes
- Does not execute or render CanvasL.

## Extraction Target
metaverse-build/formats/jsonl/

## Traceability
- [[dev-vault/Capabilities/JSONL|JSONL]]
- [[dev-vault/MOCs/Extraction-Plan]]
- [[dev-vault/MOCs/Capability-Evidence]]

## Unresolved Dependencies
- Validation tooling not extracted.
