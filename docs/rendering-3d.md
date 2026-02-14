# 3D Rendering

3D visualization and rendering capability.

## Status

Status: **extracted (frozen)**

## Capability

- Authority: automaton
- Semantic Language: TypeScript
- Adapter Languages: TypeScript

## Sources

- `sources/automaton-README.md` - Reference implementation

## Adapters

- TypeScript/JavaScript (extracted, guarded)

## Contract

Rendering is a projection only:
- Receives state from kernel
- Produces visual output
- Has no authority
- Cannot modify state
- Must be deterministic
