# Multiplayer Sync Envelope (Phase 29)

This document defines the minimal sync envelope for lifecycle events.

The envelope is a deterministic wrapper that enables multi-peer ordering
without introducing clocks or conflict resolution logic.

---

## Envelope Shape

```json
{
  "peer": "peer-A",
  "seq": 12,
  "t": "2026-01-31T00:00:00Z",
  "event": { "type": "COMPONENT_UPDATE", "entity": "cube-001", "component": "transform", "patch": {"position":[1,0,0]}, "actor": "valid:userA" }
}
```

- `peer` (string, required): sender identity
- `seq` (integer, required): monotonic per peer
- `t` (string, optional): timestamp (non-authoritative)
- `event` (object, required): lifecycle event object

Lifecycle events are defined in `runtime/world/lifecycle.md`.

---

## Ordering Rule (Phase 29)

Deterministic total order is defined as:

1. `peer` (lexicographic ascending)
2. `seq` (numeric ascending)

No clocks. No Lamport. No vector clocks.

---

## Authority Rule

Authority remains local and deterministic:

- Each peer applies the same lifecycle interpreter.
- If an event violates authority, the peer **HALTs the event** and preserves state.
- The envelope remains in the log; it simply does not mutate state.

---

## Non-Goals

- Live networking
- Conflict resolution heuristics
- CRDTs
- Signing / crypto identity

This is scaffolding for deterministic sync behavior only.
