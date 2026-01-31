# BUILD MAP

This file is the build switchboard for metaverse-build.

## Identity & Trace
### Identity (extracted, frozen)
- Authority Repo: tetragrammatron-os
- Semantic Language: YAML
- Invariant Language: unknown
- Adapter Languages: C
- Tooling: Python
- Stub: `capabilities/identity/`

### Authority-Projection (frozen; semantic core pending; invariants executable in Haskell)
- Authority Repo: tetragrammatron-os
- Semantic Language: unknown
- Invariant Language: Haskell (executable)
- Adapter Languages: C
- Tooling: unknown
- Stub: `capabilities/identity/authority/`

### Trace (extracted, frozen)
- Authority Repo: universal-life-protocol
- Semantic Language: Shell
- Invariant Language: unknown
- Adapter Languages: TypeScript/JavaScript
- Tooling: unknown
- Stub: `runtime/trace/`

### Immutable-Log (extracted, frozen)
- Authority Repo: bicf-production
- Semantic Language: Scheme (R5RS)
- Invariant Language: unknown
- Adapter Languages: Shell
- Tooling: unknown
- Stub: `runtime/log/`

### Replay (extracted, frozen)
- Authority Repo: universal-life-protocol
- Semantic Language: Shell
- Invariant Language: unknown
- Adapter Languages: Scheme (R5RS)
- Tooling: unknown
- Stub: `runtime/replay/`

## Runtime & Rendering
### 3D-Rendering (extracted, frozen)
- Authority Repo: automaton
- Semantic Language: TypeScript
- Invariant Language: unknown
- Adapter Languages: TypeScript
- Tooling: unknown
- Stub: `capabilities/rendering/3d/`

### UI-Composition (extracted, frozen)
- Authority Repo: automaton
- Semantic Language: TypeScript
- Invariant Language: unknown
- Adapter Languages: TypeScript
- Tooling: unknown
- Stub: `capabilities/ui/`

### User-Input (extracted, frozen)
- Authority Repo: automaton
- Semantic Language: TypeScript
- Invariant Language: unknown
- Adapter Languages: TypeScript
- Tooling: unknown
- Stub: `capabilities/interaction/`

## Formats
### CanvasL (extracted, frozen)
- Authority Repo: bicf-production
- Semantic Language: Scheme (R5RS)
- Invariant Language: unknown
- Adapter Languages: TypeScript, Scheme (R5RS)
- Tooling: JSON schema
- Stub: `formats/canvasl/`

### JSONL (extracted, frozen)
- Authority Repo: bicf-production
- Semantic Language: JSON
- Invariant Language: unknown
- Adapter Languages: Scheme (R5RS), TypeScript, JSONL
- Tooling: unknown
- Stub: `formats/jsonl/`

## Networking
### Sync (extracted, frozen)
- Authority Repo: universal-life-protocol
- Semantic Language: TypeScript/JavaScript
- Invariant Language: unknown
- Adapter Languages: TypeScript
- Tooling: unknown
- Stub: `runtime/sync/`

### PubSub (extracted, frozen)
- Authority Repo: universal-life-protocol
- Semantic Language: TypeScript/JavaScript
- Invariant Language: unknown
- Adapter Languages: unknown
- Tooling: unknown
- Stub: `runtime/pubsub/`

### RPC (extracted, frozen)
- Authority Repo: opencode-obsidian-agent
- Semantic Language: TypeScript
- Invariant Language: unknown
- Adapter Languages: TypeScript
- Tooling: unknown
- Stub: `runtime/rpc/`

## Tooling
### Code-Editor-Integration (extracted, frozen)
- Authority Repo: opencode-obsidian-agent
- Semantic Language: TypeScript
- Invariant Language: unknown
- Adapter Languages: TypeScript
- Tooling: unknown
- Stub: `tooling/editor/`

### Build-System (extracted, frozen)
- Authority Repo: bicf-production
- Semantic Language: Shell
- Invariant Language: unknown
- Adapter Languages: Shell, TypeScript
- Tooling: Docker
- Stub: `build/`
