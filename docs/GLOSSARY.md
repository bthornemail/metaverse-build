# Glossary of Key Terms

Reference definitions for metaverse build runtime terminology.

## A

### Authority
The right to mutate state. Enforced before any emission. If violated → HALT.
- See: [invariants.md](invariants.md), [runtime-world.md](runtime-world.md)

### Authority Gate
The executable invariant (Haskell) that validates identity before any state change.
- See: [invariants.md](invariants.md), [identity-authority.md](identity-authority.md)
- Location: `invariants/authority/`

### Adapter
A projection that transforms kernel output to external formats. Adapters are downstream only.
- See: [capabilities.md](capabilities.md), [pipelines.md](pipelines.md)

## B

### Basis
The foundational reference frame in lattice routing. Used for peer discovery and routing.
- See: [runtime-lattice.md](runtime-lattice.md)

## C

### Capability
An extracted feature that has been identified for rebuilding behind the authority gate. Each capability has an authority source.
- See: [capabilities.md](capabilities.md), [build-map.md](build-map.md)

### Checkpoint
A canonical snapshot with metadata derived from trace. Content-addressed via SHA256 hash.
- See: [runtime-checkpoint.md](runtime-checkpoint.md)

### Content-Addressing
Using SHA256 hash as the canonical identifier for state. Same content → same hash.
- See: [runtime-checkpoint.md](runtime-checkpoint.md), [golden-tests.md](golden-tests.md)

## D

### Determinism
The property that replaying the same events over the same initial state produces identical snapshots.
- See: [runtime-world.md](runtime-world.md), [golden-tests.md](golden-tests.md)

## E

### Entity
A persistent object with identity and components. The core unit of world state.
- See: [runtime-world.md](runtime-world.md), [world-ir.md](world-ir.md)

### Extracted
Status indicating a capability has been identified but needs rebuilding behind the authority gate.
- See: [build-map.md](build-map.md), [kernel-reconstruction.md](kernel-reconstruction.md)

## G

### Golden Test
A deterministic verification test using SHA256 hashes. Same content must produce same hash regardless of order.
- See: [golden-tests.md](golden-tests.md)

## H

### HALT
The safety contract. If violated:
- No emission occurs
- Zero bytes written
- Downstream unchanged
- See: [invariants.md](invariants.md), [kernel-reconstruction.md](kernel-reconstruction.md)

## I

### Identity
The actor performing an action. Must have valid schema prefix.
- See: [identity-authority.md](identity-authority.md), [capabilities.md](capabilities.md)

### Invariant
A property that must always hold. The authority gate enforces invariants before any state change.
- See: [invariants.md](invariants.md), [identity-authority.md](identity-authority.md)

### IR (Intermediate Representation)
The canonical format all capabilities compile to.
- See: [world-ir.md](world-ir.md)

## L

### Lifecycle
The six allowed mutations:
1. ENTITY_CREATE
2. ENTITY_DESTROY
3. COMPONENT_ATTACH
4. COMPONENT_UPDATE
5. COMPONENT_DETACH
6. ZONE_MOVE
- See: [runtime-world.md](runtime-world.md)

### Lattice
The peer discovery and routing system. Provides structural discovery only, no semantic authority.
- See: [runtime-lattice.md](runtime-lattice.md)

## O

### Operational
Status indicating a component is working, tested, and production-ready.
- See: [INDEX.md](INDEX.md)

### Owner
The immutable authority boundary for an entity. Actor must match owner for mutations.
- See: [runtime-world.md](runtime-world.md)

## P

### Phase
A development milestone. Phases are numbered (e.g., Phase 35B, Phase 36).
- See: [reports.md](reports.md), [evidence.md](evidence.md)

### Pipeline
An end-to-end orchestration script combining runtime components.
- See: [pipelines.md](pipelines.md)

### Plan
A content-addressed snapshot defining peer connections. Derived from lattice.
- See: [runtime-lattice.md](runtime-lattice.md)

### Projection
A downstream view of state. Non-authoritative, disposable, rebuildable.
- See: [projections.md](projections.md), [kernel-reconstruction.md](kernel-reconstruction.md)

### PubSub
Publish-subscribe messaging. Status: extracted (needs rebuilding).
- See: [runtime-pubsub.md](runtime-pubsub.md)

## R

### Replay
Deterministic event replay from trace. Same trace always produces same state.
- See: [runtime-replay.md](runtime-replay.md)

### RPC
Remote Procedure Call. Status: extracted (needs rebuilding).
- See: [runtime-rpc.md](runtime-rpc.md)

## S

### Schema Prefix
The validated portion of an identity address. Must be valid under schema rules.
- See: [identity-authority.md](identity-authority.md)

### Shard
A portable bundle of zone state + trace + checkpoint. Enables offline mobility.
- See: [runtime-shards.md](runtime-shards.md)

### Snapshot
A complete state dump. Content-addressed via SHA256.
- See: [runtime-checkpoint.md](runtime-checkpoint.md)

### Status
- **Operational**: Working, tested
- **Extracted**: Identified, needs rebuilding
- **Placeholder**: Structure exists, needs implementation
- See: [INDEX.md](INDEX.md)

### Sync
Peer-to-peer state synchronization. Status: extracted (needs rebuilding).
- See: [runtime-sync.md](runtime-sync.md), [runtime-sync-world.md](runtime-sync-world.md)

## T

### Trace
The immutable, ordered sequence of all events. Enables replay and audit.
- See: [runtime-trace.md](runtime-trace.md), [runtime-world.md](runtime-world.md)

### Transport
The message delivery layer (FIFO or TCP). Transport is lossy/unreliable; semantics handled by higher layers.
- See: [runtime-sync-transport.md](runtime-sync-transport.md)

## W

### World IR
The canonical intermediate representation. Defines entities, components, zones, rules, portals.
- See: [world-ir.md](world-ir.md)

### World
A persistent virtual space containing entities, zones, and rules.
- See: [runtime-world.md](runtime-world.md), [world-ir.md](world-ir.md)

## Z

### Zone
A spatial or logical partition of world state.
- See: [runtime-zones.md](runtime-zones.md), [world-ir.md](world-ir.md)
