---
type: contract
capability: [[dev-vault/Capabilities/Immutable-Log|Immutable-Log]]
authority: bicf-production
status: frozen
---

# Contract: Immutable-Log

## Purpose
Append-only log storage.

## Inputs
- Event entries.

## Outputs
- Append-only log records.

## Invariants
- No mutation of existing log entries.

## Failure Modes
- Does not enforce trace semantics or replay correctness.

## Extraction Target
metaverse-build/runtime/log/

## Traceability
- [[dev-vault/Capabilities/Immutable-Log|Immutable-Log]]
- [[dev-vault/MOCs/Extraction-Plan]]
- [[dev-vault/MOCs/Capability-Evidence]]

## Unresolved Dependencies
- Log storage backend not extracted.
