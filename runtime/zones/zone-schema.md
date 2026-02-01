# Hybrid Zone Model (Phase 31)

Zones are deterministic authority islands. Each entity has:

- `spatial_zone`: exactly one zone (uses entity `zone` field)
- `logical_zones`: zero or more tags (component `zone-tags`)

Spatial zones drive streaming and snapshot partitioning.
Logical zones drive rules and overlays.

---

## Invariants

- Each entity belongs to exactly one spatial zone.
- Entities may belong to multiple logical zones.
- Cross-zone interaction is message passing only.
- Zones never share mutable state.

---

## Zone Snapshot Shape

```json
{
  "world": "room",
  "zone": "zone-a",
  "state": {
    "entities": [ ... ]
  },
  "source_snapshot_hash": "..."
}
```

---

## Logical Zones

Logical zone tags are represented as a component:

```json
{
  "type": "zone-tags",
  "data": {"tags": ["market","player-owned"]}
}
```

This does not affect spatial partitioning.
