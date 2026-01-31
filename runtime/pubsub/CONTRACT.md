---
type: contract
capability: [[dev-vault/Capabilities/PubSub|PubSub]]
authority: universal-life-protocol
status: frozen
---

# Contract: PubSub

## Purpose
Publish/subscribe messaging.

## Inputs
- Topics/messages.

## Outputs
- Delivered events.

## Invariants
- Topic-based routing.

## Failure Modes
- No persistence or replay defined.

## Extraction Target
metaverse-build/runtime/pubsub/

## Traceability
- [[dev-vault/Capabilities/PubSub|PubSub]]
- [[dev-vault/MOCs/Extraction-Plan]]
- [[dev-vault/MOCs/Capability-Evidence]]

## Unresolved Dependencies
- Broker configuration not extracted.
