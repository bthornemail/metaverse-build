---
type: contract
capability: [[dev-vault/Capabilities/RPC|RPC]]
authority: opencode-obsidian-agent
status: frozen
---

# Contract: RPC

## Purpose
Runtime ↔ plugin RPC.

## Inputs
- RPC requests.

## Outputs
- RPC responses.

## Invariants
- Protocol version must be consistent.

## Failure Modes
- No transport auth defined.

## Extraction Target
metaverse-build/runtime/rpc/

## Traceability
- [[dev-vault/Capabilities/RPC|RPC]]
- [[dev-vault/MOCs/Extraction-Plan]]
- [[dev-vault/MOCs/Capability-Evidence]]

## Unresolved Dependencies
- Transport and auth not extracted.
