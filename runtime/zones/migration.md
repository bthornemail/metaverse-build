# Cross-Zone Migration Protocol (Phase 32A)

A migration moves an entity between spatial zones without shared mutable state.
The transfer is message passing: extract entity state from source zone, then apply
it to destination zone as a new authority-local entity.

---

## Transfer Record

```json
{
  "entity": { ... },
  "from": "zone-a",
  "to": "zone-b",
  "source_snapshot_hash": "..."
}
```

- `entity` is the full entity record
- `from` and `to` are spatial zone ids
- `source_snapshot_hash` anchors the source state

---

## Rules

- Entity must be removed from the source snapshot.
- Entity must be added to the destination snapshot with `zone` set to `to`.
- No shared mutable state between zones.
- Deterministic outputs for the same inputs.

---

## Authority

Migration is still subject to lifecycle authority rules.
Ownership does not change during migration.

Zone-level delegation is checked separately (Phase 32C).
