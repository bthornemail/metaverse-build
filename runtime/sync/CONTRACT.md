---
type: contract
capability: [[dev-vault/Capabilities/Sync|Sync]]
authority: universal-life-protocol
status: frozen
---

# Contract: Sync

## Purpose
Peer-to-peer synchronization.

## Inputs
- Peer updates.

## Outputs
- Synchronized state.

## Invariants
- Deterministic update ordering.

## Failure Modes
- No identity or auth layer defined.

## Extraction Target
metaverse-build/runtime/sync/

## Traceability
- [[dev-vault/Capabilities/Sync|Sync]]
- [[dev-vault/MOCs/Extraction-Plan]]
- [[dev-vault/MOCs/Capability-Evidence]]

## Unresolved Dependencies
- RPC and PubSub coupling not defined.
