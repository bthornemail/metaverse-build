---
type: invariant
capability: Authority-Projection
status: draft
invariant_language: Haskell (executable)
---

# Authority-Projection Invariant (Spike)

## Formal Statement (Plain)
An execution may proceed **iff** the acting identity’s schema prefix is valid under the governing schema rules. Invalid schema prefixes must halt execution before any state transition or trace emission.

## Inputs
- Identity address (prefix + instance bytes)
- Address schema rules (prefix validity)
- Proposed action (execution step)

## Outputs
- Decision: allow | deny
- Reason: invalid-schema-prefix | valid-schema-prefix

## Must-Never-Happen
- An invalid schema prefix produces a valid execution step.
- A trace/log is emitted for a denied execution step.

## Pseudocode
```
if not schema_prefix_valid(identity):
    deny("invalid-schema-prefix")
    halt
else:
    allow()
```

## Notes
- Executable invariant language is Haskell.
- Lean/Coq treated as academic reference only (out of scope).
- No integration or enforcement code is added here.
