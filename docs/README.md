# Metaverse Build Runtime - Documentation

This directory contains documentation for the Metaverse Build Runtime.

## Quick Start

- **[INDEX.md](INDEX.md)** - Quick reference to all docs
- **[README.md](README.md)** - Full documentation with details
- **[../AGENTS.md](../AGENTS.md)** - Instructions for AI agents

## Core Architecture

The runtime enforces: **Identity → Authority → Trace → Projection**

## Project Status

| Category | Operational | Extracted | Total |
|----------|-------------|-----------|-------|
| Runtime Components | 8 | 6 | 14 |
| Capabilities | 1 | 6 | 7 |
| System | 3 | 3 | 6 |
| Supporting | 6 | 1 | 7 |
| **Total** | **18** | **16** | **34** |

## Key Documents

| Topic | Description |
|-------|-------------|
| [kernel-reconstruction.md](kernel-reconstruction.md) | Architecture philosophy |
| [build-map.md](build-map.md) | Capability ledger |
| [invariants.md](invariants.md) | Authority gate (Haskell) |
| [runtime-world.md](runtime-world.md) | Core state management |
| [runtime-checkpoint.md](runtime-checkpoint.md) | State snapshots |
| [runtime-zones.md](runtime-zones.md) | Spatial partitioning |
| [runtime-time.md](runtime-time.md) | Timeline branching |
| [pipelines.md](pipelines.md) | End-to-end pipelines |
| [world-ir.md](world-ir.md) | Intermediate representation |

## Running Tests

```bash
# Core runtime tests
bash runtime/time/time-tests.sh
bash runtime/zones/zone-tests.sh
bash runtime/checkpoint/checkpoint-tests.sh
bash runtime/world/lifecycle-tests.sh

# Golden tests
bash scripts/golden-replay.sh

# Editor tests
bash editor/editor-tests.sh
```

## Authority Gate

All emission must pass through `AuthorityGate` (Haskell invariant). Violations result in HALT with zero bytes emitted.

See: `invariants/authority/gate/AuthorityGate.hs`
