---
type: contract
capability: [[dev-vault/Capabilities/Identity|Identity]]
authority: tetragrammatron-os
status: frozen
---

# Contract: Identity

## Purpose
Schema-gated identity/address validation.

## Inputs
- `address-schema.yaml`

## Outputs
- Valid/invalid schema prefix decisions.

## Invariants
- Invalid schema prefixes cannot execute.

## Failure Modes
- Does not handle authentication, credentials, or user lifecycle.

## Extraction Target
metaverse-build/capabilities/identity/

## Traceability
- [[dev-vault/Capabilities/Identity|Identity]]
- [[dev-vault/MOCs/Extraction-Plan]]
- [[dev-vault/MOCs/Capability-Evidence]]

## Unresolved Dependencies
- None specified in docs.
