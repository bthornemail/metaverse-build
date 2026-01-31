---
type: contract
capability: [[dev-vault/Capabilities/3D-Rendering|3D-Rendering]]
authority: automaton
status: frozen
---

# Contract: 3D-Rendering

## Purpose
WebGL 3D visualization.

## Inputs
- Scene graph, geometry, assets.

## Outputs
- Rendered frames.

## Invariants
- Deterministic render given scene state.

## Failure Modes
- No asset loading or physics implemented here.

## Extraction Target
metaverse-build/capabilities/rendering/3d/

## Traceability
- [[dev-vault/Capabilities/3D-Rendering|3D-Rendering]]
- [[dev-vault/MOCs/Extraction-Plan]]
- [[dev-vault/MOCs/Capability-Evidence]]

## Unresolved Dependencies
- Scene graph + asset loading not extracted.
