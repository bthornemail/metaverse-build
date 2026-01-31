---
type: justification
capability: [[dev-vault/Capabilities/Trace|Trace]]
authority: universal-life-protocol
status: frozen
---

# Capability Justification: Trace

## Purpose
Produce deterministic, verifiable execution traces.

## Authority
universal-life-protocol defines trace as the core execution artifact.

## Inputs
- Execution inputs (stdin + dotfile-defined rules).

## Outputs
- Deterministic trace logs.

## Invariants
- Same inputs must produce byte-identical outputs.

## Failure Modes
- Does not define UI or rendering; purely execution trace.

## Extraction Target
metaverse-build/runtime/trace/

## Traceability
- [[dev-vault/Capabilities/Trace|Trace]]
- [[dev-vault/Repos/universal-life-protocol|universal-life-protocol]]
- /home/main/devops/universal-life-protocol/README.md
