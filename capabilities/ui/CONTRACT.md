---
type: contract
capability: [[dev-vault/Capabilities/UI-Composition|UI-Composition]]
authority: automaton
status: frozen
---

# Contract: UI-Composition

## Purpose
UI layout and composition.

## Inputs
- UI state, events.

## Outputs
- UI panels and overlays.

## Invariants
- UI is driven by explicit state.

## Failure Modes
- No editor integration or rendering engine defined here.

## Extraction Target
metaverse-build/capabilities/ui/

## Traceability
- [[dev-vault/Capabilities/UI-Composition|UI-Composition]]
- [[dev-vault/MOCs/Extraction-Plan]]
- [[dev-vault/MOCs/Capability-Evidence]]

## Unresolved Dependencies
- Rendering engine and scene graph not extracted.
