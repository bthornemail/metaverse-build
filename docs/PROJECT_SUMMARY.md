# Project Summary

Extended overview of all operational components in the Metaverse Build Runtime.

---

## Overview

The Metaverse Build Runtime is a capability kernel that enforces **Identity → Authority → Trace → Projection**. It provides deterministic, reproducible world state management with authority enforcement at its core.

This document details all working components and their interrelationships.

---

## Core Runtime Components

### 1. World State (runtime-world)

**Status:** Operational ✅

The foundation of the entire system. Manages entities and their lifecycle.

**Features:**
- Entity management (create, destroy)
- Component system (attach, update, detach)
- Zone movement
- Deterministic event processing
- Authority enforcement

**Lifecycle Events:**
1. ENTITY_CREATE
2. ENTITY_DESTROY
3. COMPONENT_ATTACH
4. COMPONENT_UPDATE
5. COMPONENT_DETACH
6. ZONE_MOVE

**Files:**
- `apply-event.py` - Apply event to state
- `replay.py` - Replay from trace
- `materialize.py` - Materialize from IR

**Tests:** `lifecycle-tests.sh`

---

### 2. Zones (runtime-zones)

**Status:** Operational ✅

Spatial and logical partitioning of world state.

**Features:**
- Zone creation and management
- Authority delegation policies
- Spatial routing
- Interest management
- Cross-zone migration

**Zone Types:**
- Spatial zones (tile-based)
- Logical zones (overlay)

**Authority Policy:**
```json
{
  "zone-a": ["valid:userA"],
  "zone-b": ["valid:userB"],
  "*": ["valid:admin"]
}
```

**Files:**
- `route-event.py` - Route events to zones
- `migrate-entity.py` - Entity migration
- `authority-check.py` - Authority validation

**Tests:** `zone-tests.sh`, `authority-tests.sh`, `interest-tests.sh`, `migration-tests.sh`

---

### 3. Checkpoints (runtime-checkpoint)

**Status:** Operational ✅

Content-addressed state snapshots.

**Features:**
- Deterministic snapshot creation
- SHA256 content-addressing
- Corruption detection
- Rolling checkpoints
- Window replay

**Checkpoint Format:**
```json
{
  "zone": "zone-a",
  "trace": "zone-a.trace.jsonl",
  "snapshot": "zone-a.snapshot.json",
  "last_index": 42,
  "snapshot_hash": "sha256...",
  "timestamp": "2026-02-01T00:00:00Z"
}
```

**Files:**
- `checkpoint.py` - Create checkpoint
- `restore.py` - Restore from checkpoint
- `rolling-checkpoint.py` - Rolling checkpoints
- `prune.py` - Prune old data

**Tests:** `checkpoint-tests.sh`, `rolling-tests.sh`

---

### 4. Time Engine (runtime-time)

**Status:** Operational ✅

Timeline management with branching support.

**Features:**
- Timeline DAG structure
- Checkpoint references
- Branch creation
- Time window materialization
- Timeline merging

**Timeline Structure:**
```json
{
  "world": "room",
  "timeline": "main",
  "nodes": {
    "ck-1": {"checkpoint": "...", "parent": null},
    "ck-2": {"checkpoint": "...", "parent": "ck-1"}
  }
}
```

**Merge Rules:**
- Same world required
- Valid checkpoints required
- Identical snapshot hashes
- Fails if: `replay(genesis, A) != replay(genesis, B)`

**Files:**
- `branch.py` - Create branches
- `materialize.py` - Materialize windows

**Tests:** `time-tests.sh`, `merge-tests.sh`

---

### 5. Shards (runtime-shards)

**Status:** Operational ✅

Distributed persistence and offline mobility.

**Features:**
- Bundle zone state + trace + checkpoint
- Deterministic hash verification
- Offline integrity checks
- Mobility simulation

**Bundle Layout:**
```
shard/<zone>/
├── manifest.json
├── zone.snapshot.json
├── zone.trace.jsonl
└── zone.checkpoint.json
```

**Files:**
- `bundle.py` - Create shard bundle
- `restore.py` - Restore from shard

**Tests:** `shard-tests.sh`

---

### 6. Sync Transport (runtime-sync-transport)

**Status:** Operational ✅

POSIX bus message delivery.

**Features:**
- FIFO (named pipe) mode
- TCP socket mode
- Mode selection via bus.env
- Chaos testing support

**Contract:**
- Transport is lossy
- Transport is unordered
- Application handles semantics

**Files:**
- `send.sh` - Send message
- `receive.sh` - Receive message
- `chaos.sh` - Chaos testing

**Tests:** `transport-tests.sh`

---

### 7. Sync World (runtime-sync-world)

**Status:** Operational ✅

Multiplayer synchronization envelopes.

**Features:**
- Deterministic peer ordering
- No clocks required
- Authority preserved locally
- Envelope format

**Ordering Rule:**
1. peer (lexicographic ascending)
2. seq (numeric ascending)

**Envelope Format:**
```json
{
  "peer": "peer-A",
  "seq": 12,
  "event": { ... }
}
```

**Files:**
- `append.sh` - Append event
- `merge.sh` - Merge envelopes
- `apply-merged.sh` - Apply merged

**Tests:** `simulate-two-peers.sh`

---

### 8. Lattice (runtime-lattice)

**Status:** Operational ✅

Peer discovery and routing.

**Features:**
- Seed-based discovery
- Append-only observation
- Peer graph construction
- Basis routing
- Connection plans
- Live rebind

**Directories:**
- `peers/seeds.d` - Authoritative seeds
- `peers/observe` - Observations
- `graph` - Peer graph + basis
- `plan` - Connection plans
- `compiler` - Observer/compiler
- `reconcile` - Tick + rebind

---

## Authority System

### Authority Gate (invariants/authority)

**Status:** Operational ✅

The Haskell executable invariant that enforces the core law.

**Function:**
```haskell
validateAuthority :: Identity -> Trace -> Either AuthorityViolation ValidatedTrace
```

**Violations:**
- InvalidSchemaPrefix
- UnknownAuthority
- CrossDomainEscalation

**On Violation:**
- No emission
- Zero bytes written
- Downstream unchanged

---

## Projection Layer

### Mind-Git (projections/mind-git)

**Status:** Operational ✅

Downstream projection that produces human-readable outputs.

**Outputs:**
- Canvas views (Obsidian)
- Reports
- Plan history
- Content-addressed store

**Run:**
```bash
bash pipelines/mind-git/run.sh
bash pipelines/mind-git/export-vault.sh
```

---

## World IR

**Status:** Operational ✅

Canonical intermediate representation.

**Schema Types:**
- World
- Entity
- Component
- Zone
- Rule
- Event
- Portal
- Attachment

**Files:**
- `SCHEMA.md` - Full schema
- `compiler/world-compile.sh` - IR compiler

---

## Pipeline System

**Status:** Operational ✅

End-to-end orchestration.

**Key Pipelines:**
- `identity-trace-log-replay.sh` - Basic flow
- `identity-trace-authority-sync.sh` - With sync
- `mind-git/run.sh` - Projection
- `esp32/phase20A-run.sh` - ESP32 deployment

---

## Testing Infrastructure

### Golden Tests

**Status:** Operational ✅

Deterministic verification using SHA256 hashes.

**Fixtures:**
- `mini.input.json` - Minimal case
- `multi.input.json` - Multiple events
- `failure.input.json` - Failure case

Each has `.replay-hash` for verification.

---

## Technical Stack

| Layer | Technology |
|-------|------------|
| Authority Gate | Haskell |
| Runtime | Python, Shell |
| Transport | POSIX FIFO/TCP |
| Firmware | C (ESP-IDF) |
| IR | JSON |

---

## Phase History

| Phase | Component |
|-------|-----------|
| 17-18 | Basic pipeline |
| 19 | Fanout |
| 20A | ESP32 POSIX |
| 22 | Extended ESP32 |
| 23 | Lattice/Beacon |
| 24 | Mind-git |
| 26 | World load |
| 27 | Lifecycle |
| 28 | Editor |
| 29 | Sync envelopes |
| 30A | Transport |
| 31 | Zones |
| 32 | Authority/Migration |
| 33A | Checkpoint |
| 33B | Rolling checkpoint |
| 34 | Shards |
| 35B | Time engine |
| 36 | Merge |

---

## Interdependencies

```
World State
    │
    ├──▶ Zones ──────────────▶ Checkpoint ──▶ Shards
    │       │                        │
    │       └──▶ Interest ───────────┘
    │
    ├──▶ Time Engine ────────▶ Merge
    │
    └──▶ Sync Transport ──────▶ Sync World
            │
            └──▶ Lattice (peer discovery)

All ──▶ Authority Gate ──▶ Trace ──▶ Projection
```

---

## Summary

The system provides:
- **8 operational runtime components**
- **Deterministic state management**
- **Authority enforcement at the kernel level**
- **Content-addressed snapshots**
- **Offline-capable shards**
- **Multiplayer sync with ordering guarantees**
- **Peer discovery infrastructure**

All connected through the fundamental invariant: **Identity → Authority → Trace → Projection**
