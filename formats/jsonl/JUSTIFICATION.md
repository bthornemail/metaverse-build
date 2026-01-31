---
type: justification
capability: [[dev-vault/Capabilities/JSONL|JSONL]]
authority: bicf-production
status: frozen
---

# Capability Justification: JSONL

## Purpose
Provide JSONL schema for CanvasL records.

## Authority
bicf-production defines the CanvasL JSONL schema.

## Inputs
- JSONL records.

## Outputs
- Schema validation rules.

## Invariants
- Records conform to schema.

## Failure Modes
- Does not parse or render records.

## Extraction Target
metaverse-build/formats/jsonl/

## Traceability
- [[dev-vault/Capabilities/JSONL|JSONL]]
- [[dev-vault/Repos/bicf-production|bicf-production]]
- /home/main/devops/bicf-production/README.md
