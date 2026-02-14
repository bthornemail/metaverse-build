# Metaverse Build Runtime - Documentation Index

Quick reference to all documentation in this folder.

## Quick Start

| Topic | File |
|-------|------|
| Executive Summary | [../EXECUTIVE_SUMMARY.md](../EXECUTIVE_SUMMARY.md) |
| Project Summary | [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) |
| Project Overview | [README.md](README.md) |
| Architecture | [kernel-reconstruction.md](kernel-reconstruction.md) |
| Agent Instructions | [../AGENTS.md](../AGENTS.md) |
| Glossary | [GLOSSARY.md](GLOSSARY.md) |

## Runtime Components (Operational)

| Component | Doc | Status |
|-----------|-----|--------|
| World State & Lifecycle | [runtime-world.md](runtime-world.md) | ✅ |
| Zones (spatial partitioning) | [runtime-zones.md](runtime-zones.md) | ✅ |
| Checkpoints (state snapshots) | [runtime-checkpoint.md](runtime-checkpoint.md) | ✅ |
| Time Engine (branching) | [runtime-time.md](runtime-time.md) | ✅ |
| Shards (persistence) | [runtime-shards.md](runtime-shards.md) | ✅ |
| Transport (FIFO/TCP) | [runtime-sync-transport.md](runtime-sync-transport.md) | ✅ |
| Multiplayer Sync | [runtime-sync-world.md](runtime-sync-world.md) | ✅ |
| Lattice (peer discovery) | [runtime-lattice.md](runtime-lattice.md) | ✅ |

## Runtime Components (Extracted)

| Component | Doc | Status |
|-----------|-----|--------|
| Immutable Log | [runtime-log.md](runtime-log.md) | 🔄 |
| PubSub | [runtime-pubsub.md](runtime-pubsub.md) | 🔄 |
| Replay | [runtime-replay.md](runtime-replay.md) | 🔄 |
| RPC | [runtime-rpc.md](runtime-rpc.md) | 🔄 |
| Sync | [runtime-sync.md](runtime-sync.md) | 🔄 |
| Trace | [runtime-trace.md](runtime-trace.md) | 🔄 |

## Capabilities

| Capability | Doc |
|------------|-----|
| Identity Authority | [identity-authority.md](identity-authority.md) |
| 3D Rendering | [rendering-3d.md](rendering-3d.md) |
| UI Composition | [capability-ui.md](capability-ui.md) |
| User Input | [capability-user-input.md](capability-user-input.md) |
| Audio | [capability-audio.md](capability-audio.md) |
| Networking | [capability-networking.md](capability-networking.md) |
| Overview | [capabilities.md](capabilities.md) |

## System

| Topic | Doc |
|-------|-----|
| Authority Gate | [invariants.md](invariants.md) |
| Pipelines | [pipelines.md](pipelines.md) |
| Projections | [projections.md](projections.md) |
| World IR | [world-ir.md](world-ir.md) |
| Profiles | [profiles.md](profiles.md) |
| Firmware | [firmware.md](firmware.md) |

## Supporting

| Topic | Doc |
|-------|-----|
| Scripts | [scripts.md](scripts.md) |
| Golden Tests | [golden-tests.md](golden-tests.md) |
| Editor Tools | [editor.md](editor.md) |
| Formats | [formats.md](formats.md) |
| Tooling | [tooling.md](tooling.md) |
| Build System | [build-system.md](build-system.md) |

## Archives

| Topic | Doc |
|-------|-----|
| Evidence | [evidence.md](evidence.md) |
| Reports | [reports.md](reports.md) |
| Build Map | [build-map.md](build-map.md) |

## Legend

- ✅ Operational: Working, tested, production-ready
- 🔄 Extracted: Identified, needs rebuilding behind authority gate
- 🔄 Placeholder: Structure exists, needs full implementation
