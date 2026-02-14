# UI Composition

UI composition and rendering capability.

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

UI composition is a projection only:
- Receives state from kernel
- Composes UI elements
- Has no authority
- Cannot modify state
- Must be deterministic
