# Profiles

Runtime configuration profiles for the metaverse kernel.

## Kernel V1

Profile: `kernel-v1` (version 0.1.0)

Defines the minimal governed runtime:
- Single AuthorityGate
- Approved pipelines
- Explicit projection lanes

### Key Characteristics

- UI, pubsub, and other projections are **non-authoritative**
- Projections must remain downstream of the gate
- MQTT is superseded by native POSIX lattice transports

### Profile Files

- `PROFILE.md` - Profile definition
- `MANIFEST.json` - Component manifest
- `TOPOLOGY.md` - Network topology
- `PIPELINES.md` - Approved pipelines
- `OPERATIONS.md` - Operations guide
- `ARTIFACTS.md` - Expected artifacts
- `FAILURES.md` - Failure modes
- `QOS.md` - Quality of service

## Purpose

Profiles define operational constraints and runtime configuration. They are used to:
- Configure the kernel
- Define approved capabilities
- Set operational boundaries
