# Zones Runtime

Spatial and logical partitioning with authority delegation.

## Overview

Zones are spatial or logical partitions of world state. Each zone has its own authority policy controlling which actors can emit events targeting that zone.

## Zone Authority (Phase 32C)

Zone authority defines which actors may emit lifecycle events targeting a zone. This is an additional guardrail on top of entity ownership.

## Policy Shape

```json
{
  "zone-a": ["valid:userA"],
  "zone-b": ["valid:userB"],
  "*": ["valid:admin"]
}
```

- Zone-specific lists are allowed actors
- `*` is a global allow list

## Rule

An event targeting a zone is allowed if:
- actor is in `policy[zone]`, or
- actor is in `policy[*]`

Otherwise, HALT with `ZoneNotAuthorized`.

## Zone Schema

```json
{
  "id": "zone-a",
  "bounds": {"min": [0, 0, 0], "max": [10, 10, 10]},
  "tags": ["spawn", "safe"]
}
```

## Files

- `route-event.py` - Route event to appropriate zone
- `zone-materialize.py` - Materialize zone state
- `migrate-entity.py` - Migrate entity between zones
- `apply-migration.py` - Apply zone migration
- `authority-check.py` - Check zone authority
- `interest.py` - Determine zone interest
- `authority-tests.sh` - Authority tests
- `interest-tests.sh` - Interest tests
- `migration-tests.sh` - Migration tests
- `zone-tests.sh` - Zone tests

## Usage

```bash
# Route event
python3 route-event.py <event_json> <zone_policy>

# Migrate entity
python3 migrate-entity.py <snapshot> <entity_id> <target_zone> <output_snapshot>

# Check authority
python3 authority-check.py <actor> <zone> <policy>
```

## Tests

```bash
bash runtime/zones/zone-tests.sh
bash runtime/zones/authority-tests.sh
bash runtime/zones/interest-tests.sh
bash runtime/zones/migration-tests.sh
```

## Notes

- Zone authority does not change entity ownership
- Ownership checks still apply
- This phase does not add delegation or transfer

## Interest Management (Phase 32B)

Interest sets determine which spatial zones a client should load.

### Tile Naming

Spatial zones use the format: `"tile-X-Y"` where X and Y are integers.

### Interest Rule

Given a center tile and radius R, the interest set is all tiles in the square neighborhood:

```
[x-R, x+R] × [y-R, y+R]
```

Deterministic ordering is lexicographic by X then Y.

### Non-Goals

- Visibility culling
- Distance-based scoring
- Physics-driven interest

This is scaffolding only.

## Cross-Zone Migration Protocol (Phase 32A)

A migration moves an entity between spatial zones without shared mutable state. The transfer is message passing: extract entity state from source zone, then apply it to destination zone as a new authority-local entity.

### Transfer Record

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

### Rules

- Entity must be removed from the source snapshot
- Entity must be added to the destination snapshot with `zone` set to `to`
- No shared mutable state between zones
- Deterministic outputs for the same inputs

### Authority

Migration is still subject to lifecycle authority rules. Ownership does not change during migration. Zone-level delegation is checked separately (Phase 32C).
