# Build System

Build system integration and tooling.

## Status

Status: **extracted (frozen)**

## Capability

- Authority: bicf-production
- Semantic Language: Shell
- Adapter Languages: Shell, TypeScript
- Tooling: Docker

## Sources

- `sources/bicf-README.md` - Build system reference

## Adapters

- Shell (extracted, guarded)
- TypeScript (extracted, guarded)

## Contract

Build system must:
1. Pass through AuthorityGate
2. Emit trace events
3. Be reproducible
4. Produce deterministic outputs
