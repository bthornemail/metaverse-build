---
type: justification
capability: [[dev-vault/Capabilities/UI-Composition|UI-Composition]]
authority: automaton
status: frozen
---

# Capability Justification: UI-Composition

## Purpose
Compose UI panels/overlays for metaverse runtime.

## Authority
automaton declares UI & visualization layer.

## Inputs
- UI state and events.

## Outputs
- UI panels, overlays, inspector views.

## Invariants
- UI state changes are deterministic.

## Failure Modes
- Does not define editor integration.

## Extraction Target
metaverse-build/capabilities/ui/

## Traceability
- [[dev-vault/Capabilities/UI-Composition|UI-Composition]]
- [[dev-vault/Repos/automaton|automaton]]
- /home/main/devops/automaton/README.md
