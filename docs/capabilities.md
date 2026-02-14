# Capabilities

Extracted capability stubs for the metaverse kernel.

## Overview

Capabilities are extracted from legacy projects and rebuilt as adapters behind the authority gate. Each capability has a specific authority source and must be rebuilt to enforce kernel invariants.

## Identity

Status: **extracted (frozen)**

- Authority: tetragrammatron-os
- Semantic Language: YAML
- Adapter Languages: C
- Sources: `sources/address-schema.yaml`

### Identity Authority

- Status: **operational** (in invariants/authority/)
- See: [identity-authority.md](identity-authority.md)

## Interaction

Status: **extracted (frozen)**

- Capability: User input handling
- Authority: automaton
- Semantic Language: TypeScript
- Adapter Languages: TypeScript

## UI

Status: **extracted (frozen)**

- Capability: UI composition
- Authority: automaton
- Semantic Language: TypeScript
- Adapter Languages: TypeScript

## Rendering

Status: **extracted (frozen)**

- Capability: 3D rendering
- Authority: automaton
- Semantic Language: TypeScript
- Adapter Languages: TypeScript

### 3D Rendering

- Status: **extracted**
- See: [rendering-3d.md](rendering-3d.md)

### User Input

- Status: **extracted**
- See: [capability-user-input.md](capability-user-input.md)

### UI Composition

- Status: **extracted**
- See: [capability-ui.md](capability-ui.md)

## Audio

Status: **extracted (frozen)**

- Capability: Audio processing
- See: [capability-audio.md](capability-audio.md)

## Networking

Status: **extracted (frozen)**

- Capability: Network communication
- See: [capability-networking.md](capability-networking.md)

## Contract

All capabilities must:
1. Pass through AuthorityGate
2. Emit trace events
3. Compile to World IR
4. Be downstream projections only

## Next Steps

Each capability needs:
1. Reimplementation behind AuthorityGate
2. Trace emission
3. World IR compilation
4. Adapter extraction
