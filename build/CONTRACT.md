---
type: contract
capability: [[dev-vault/Capabilities/Build-System|Build-System]]
authority: bicf-production
status: frozen
---

# Contract: Build-System

## Purpose
Build/deploy pipeline.

## Inputs
- Source code.

## Outputs
- Build artifacts.

## Invariants
- Reproducible builds.

## Failure Modes
- No runtime logic.

## Extraction Target
metaverse-build/build/

## Traceability
- [[dev-vault/Capabilities/Build-System|Build-System]]
- [[dev-vault/MOCs/Extraction-Plan]]
- [[dev-vault/MOCs/Capability-Evidence]]

## Unresolved Dependencies
- CI/CD config not extracted.
