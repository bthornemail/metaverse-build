---
type: justification
capability: [[dev-vault/Capabilities/Build-System|Build-System]]
authority: bicf-production
status: frozen
---

# Capability Justification: Build-System

## Purpose
Canonical build/deploy pipeline for metaverse build.

## Authority
bicf-production documents build + deployment system.

## Inputs
- Source code.

## Outputs
- Build artifacts, deployment configs.

## Invariants
- Build stages must be deterministic.

## Failure Modes
- Does not define runtime semantics.

## Extraction Target
metaverse-build/build/

## Traceability
- [[dev-vault/Capabilities/Build-System|Build-System]]
- [[dev-vault/Repos/bicf-production|bicf-production]]
- /home/main/devops/bicf-production/README.md
