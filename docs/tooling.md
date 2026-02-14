# Tooling

Editor and development tool integrations.

## Code Editor Integration

Status: **extracted (frozen)**

- Authority: opencode-obsidian-agent
- Semantic Language: TypeScript
- Adapter Languages: TypeScript

## Tools

### opencode Integration

- Status: extracted (frozen)
- Adapters: TypeScript (extracted, guarded)

### hyperdev-ide

- Status: extracted (frozen)
- Adapters: TypeScript (extracted, guarded)

### hyperdev-vr

- Status: extracted (frozen)
- Adapters: TypeScript (extracted, guarded)

## Tooling Contract

Tools are projections, not authorities. They must:
1. Pass through AuthorityGate for any world modification
2. Emit trace events for all actions
3. Be downstream of the kernel
