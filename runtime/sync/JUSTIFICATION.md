---
type: justification
capability: [[dev-vault/Capabilities/Sync|Sync]]
authority: universal-life-protocol
status: frozen
---

# Capability Justification: Sync

## Purpose
Synchronize state across peers.

## Authority
universal-life-protocol includes p2p-server for trace sharing.

## Inputs
- Peer updates.

## Outputs
- Synchronized state.

## Invariants
- Deterministic sync semantics (per ULP).

## Failure Modes
- Does not define UI collaboration.

## Extraction Target
metaverse-build/runtime/sync/

## Traceability
- [[dev-vault/Capabilities/Sync|Sync]]
- [[dev-vault/Repos/universal-life-protocol|universal-life-protocol]]
- /home/main/devops/universal-life-protocol/apps/p2p-server/README.md
