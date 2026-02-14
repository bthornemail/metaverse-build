# Invariants

Executable authority gate that enforces kernel invariants.

## Authority-Projection (Haskell)

Status: **operational**

This module is **not a utility**. It is the **gatekeeper of reality**.

- Encodes authority law as executable semantics
- Halts on violation **before** any projection or IO
- Must remain pure, total, and lazy

### Core Function

```haskell
validateAuthority :: Identity -> Trace -> Either AuthorityViolation ValidatedTrace
```

### Violation Types

- `InvalidSchemaPrefix` - Identity prefix invalid
- `UnknownAuthority` - Authority not recognized
- `CrossDomainEscalation` - Cross-domain attempt

### Files

- `AuthorityProjection.hs` - Core validation logic
- `gate/AuthorityGate.hs` - Gate executable
- `tests/Spec.hs` - Test suite
- `tests/Fixtures.hs` - Test fixtures

## Running Tests

```bash
# From repo root
cd invariants/authority
cabal build
cabal test

# Or directly
runhaskell tests/Spec.hs
```

## Contract

If validation returns `Left`:
- No emission occurs
- Zero bytes written
- Downstream unchanged

This is the primary invariant of the system.
