---
type: contract
capability: [[dev-vault/Capabilities/Authority-Projection|Authority-Projection]]
authority: tetragrammatron-os
status: frozen
---

# Contract: Authority-Projection

## Purpose
Schema-gated authority enforcement.

## Inputs
- Schema-gate semantics (pending isolation of semantic core).

## Outputs
- Execution authorization decisions.

## Invariants
- Invalid schema prefixes cannot execute.

## Failure Modes
- Does not define runtime policy engines or identity providers.

## Extraction Target
metaverse-build/capabilities/identity/authority/

## Traceability
- [[dev-vault/Capabilities/Authority-Projection|Authority-Projection]]
- [[dev-vault/MOCs/Extraction-Plan]]
- [[dev-vault/MOCs/Capability-Evidence]]
- `INVARIANT.md`

## Unresolved Dependencies
- Semantic core language for authority projection is not isolated.
- Invariant enforcement mechanism not implemented (see `INVARIANT.md`).
