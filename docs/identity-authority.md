# Identity Authority

Authority-Projection invariant implementation for identity validation.

## Overview

The identity authority module defines the invariant for validating identity prefixes and preventing unauthorized state transitions.

## Invariant

### Formal Statement

An execution may proceed **iff** the acting identity's schema prefix is valid under the governing schema rules. Invalid schema prefixes must halt execution before any state transition or trace emission.

### Inputs

- Identity address (prefix + instance bytes)
- Address schema rules (prefix validity)
- Proposed action (execution step)

### Outputs

- Decision: allow | deny
- Reason: invalid-schema-prefix | valid-schema-prefix

### Must-Never-Happen

- An invalid schema prefix produces a valid execution step.
- A trace/log is emitted for a denied execution step.

### Implementation

Executable invariant language: Haskell

```haskell
if not schema_prefix_valid(identity):
    deny("invalid-schema-prefix")
    halt
else:
    allow()
```

## Contract

See: `capabilities/identity/authority/CONTRACT.md`
