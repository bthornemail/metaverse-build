---
type: contract
capability: [[dev-vault/Capabilities/Trace|Trace]]
authority: universal-life-protocol
status: frozen
---

# Contract: Trace

## Purpose
Deterministic execution traces.

## Inputs
- stdin + world definitions.

## Outputs
- Trace log artifacts.

## Invariants
- Same inputs → byte-identical outputs.

## Failure Modes
- Does not include distributed sync or UI.

## Extraction Target
metaverse-build/runtime/trace/

## Traceability
- [[dev-vault/Capabilities/Trace|Trace]]
- [[dev-vault/MOCs/Extraction-Plan]]
- [[dev-vault/MOCs/Capability-Evidence]]

## Unresolved Dependencies
- World definition format and lifecycle not extracted yet.
