---
type: justification
capability: [[dev-vault/Capabilities/User-Input|User-Input]]
authority: automaton
status: frozen
---

# Capability Justification: User-Input

## Purpose
Capture and normalize user input for interaction.

## Authority
automaton declares interactive WebGL UI.

## Inputs
- Pointer/gesture/controller events.

## Outputs
- Interaction events and commands.

## Invariants
- Input events are captured and routed deterministically.

## Failure Modes
- Does not define physics or gameplay.

## Extraction Target
metaverse-build/capabilities/interaction/

## Traceability
- [[dev-vault/Capabilities/User-Input|User-Input]]
- [[dev-vault/Repos/automaton|automaton]]
- /home/main/devops/automaton/README.md
