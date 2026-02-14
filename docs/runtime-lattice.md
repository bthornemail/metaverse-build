# Lattice Runtime (Phase 23)

Structural discovery and routing only. No semantic authority.

## Overview

The lattice system provides peer discovery, basis routing, live rebind, plan hashing, and structural diffs. It is a structural layer that does not handle semantic authority.

## Directories

- `peers/seeds.d` - Authoritative seeds
- `peers/observe` - Append-only observations
- `graph` - Derived peergraph + basis
- `plan` - Derived connection-plan + device-plan
- `compiler` - Observer/compiler/projector
- `reconcile` - Tick + rebind
- `trace` - Discovery + routing

## Key Concepts

### Peer Discovery
Peers are discovered through seeds and observation.

### Basis Routing
Routes are computed based on peer graph basis.

### Plan Hashing
Plans are content-addressed snapshots.

### Live Rebind
Connections can be rebound dynamically.

### Structural Diffs
Diffs are deterministic and structural.

## Files

- `bin/beacon-listen.sh` - Listen for beacons
- `bin/beacon-send.sh` - Send beacons
- `bin/run.sh` - Run lattice
- `bin/graph-basis-compiler.sh` - Compile graph basis
- `bin/peer-observer.sh` - Observe peers

## Usage

```bash
# Run lattice beacon demo
bash pipelines/lattice/phase23A-beacon-demo.sh
```

## Contract

- Lattice provides structural discovery only
- No semantic authority enforcement
- Authority remains in AuthorityGate
- Plans are content-addressed snapshots
