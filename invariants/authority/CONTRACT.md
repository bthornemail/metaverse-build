---
type: contract
capability: Authority-Projection
status: frozen
---

# Executable Invariant Contract: Authority-Projection

## Inputs
- `Identity`
- `Trace`

## Outputs
- `Either AuthorityViolation ValidatedTrace`

## Must Never Happen
- A trace with an invalid identity schema prefix is projected.
- Authority escalation across domains without explicit rule.
- Projection occurs without prior validation.

## Halting Semantics
- `Left` means **halt immediately**.
- `Right` means projection is allowed.

## Adapter Rule
Adapters MUST call `validateAuthority` and MUST halt on `Left`.

## Notes
- No IO, no parsing, no effects.
- No dependencies beyond `base`.
