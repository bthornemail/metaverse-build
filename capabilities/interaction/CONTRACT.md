---
type: contract
capability: [[dev-vault/Capabilities/User-Input|User-Input]]
authority: automaton
status: frozen
---

# Contract: User-Input

## Purpose
User input handling.

## Inputs
- Pointer/gesture/controller events.

## Outputs
- Interaction events and commands.

## Invariants
- Deterministic input routing.

## Failure Modes
- No physics or rendering defined here.

## Extraction Target
metaverse-build/capabilities/interaction/

## Traceability
- [[dev-vault/Capabilities/User-Input|User-Input]]
- [[dev-vault/MOCs/Extraction-Plan]]
- [[dev-vault/MOCs/Capability-Evidence]]

## Unresolved Dependencies
- Event schema not extracted.
