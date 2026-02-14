# Sync Transport Runtime

POSIX bus transport layer for message delivery between peers.

## Overview

Transport is lossy, unordered, and hostile. Kernel correctness must not depend on transport behavior. Transport is a projection layer, not a semantic layer.

## Transport Modes

- **FIFO** - Named pipe communication
- **TCP** - Socket-based communication

Mode is selected via `bus.env` derived from lattice connection plan.

## Files

- `send.sh` - Send message via transport
- `receive.sh` - Receive message via transport
- `transport-tests.sh` - Transport tests
- `chaos.sh` - Chaos testing for transport resilience

## Usage

```bash
# Send message
bash send.sh <bus_mode> <endpoint> <message>

# Receive message
bash receive.sh <bus_mode> <endpoint>
```

## Tests

```bash
bash runtime/sync-transport/transport-tests.sh
```

## Contract

- Transport may lose messages
- Transport may reorder messages
- Transport may duplicate messages
- Application must handle all above via semantic layer (checkpoint/replay)

## Non-Goals

- Guaranteed delivery
- Message ordering
- Duplicate detection

These are handled by higher layers (checkpoint, replay).
