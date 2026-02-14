# World Runtime

Core world state management and lifecycle event processing.

## Overview

The lifecycle is the only allowed change surface. All higher-level features must compile to these operations.

## Event Grammar (Six Operations)

### 1. ENTITY_CREATE
Create a persistent entity.
```json
{ "type": "ENTITY_CREATE", "id": "entity-id", "owner": "valid:userA", "actor": "valid:userA" }
```

### 2. ENTITY_DESTROY
Remove an entity.
```json
{ "type": "ENTITY_DESTROY", "id": "entity-id", "actor": "valid:userA" }
```

### 3. COMPONENT_ATTACH
Attach a component to an entity.
```json
{ "type": "COMPONENT_ATTACH", "entity": "entity-id", "component": "transform", "data": {...}, "actor": "valid:userA" }
```

### 4. COMPONENT_UPDATE
Update a component's data.
```json
{ "type": "COMPONENT_UPDATE", "entity": "entity-id", "component": "transform", "patch": {...}, "actor": "valid:userA" }
```

### 5. COMPONENT_DETACH
Remove a component from an entity.
```json
{ "type": "COMPONENT_DETACH", "entity": "entity-id", "component": "transform", "actor": "valid:userA" }
```

### 6. ZONE_MOVE
Move entity to a zone.
```json
{ "type": "ZONE_MOVE", "entity": "entity-id", "zone": "zone-id", "actor": "valid:userA" }
```

## Authority Semantics

- Every entity has an immutable `owner`
- Every mutating event must include an `actor`
- If `actor != owner` for the target entity → **HALT**
- Missing `actor` or `owner` → **HALT**

## Files

- `apply-event.py` - Apply event to state
- `replay.py` - Replay events from trace
- `materialize.py` - Materialize world from IR
- `load-ir.sh` - Load IR into world state
- `lifecycle-tests.sh` - Lifecycle tests

## Usage

```bash
# Apply event
python3 apply-event.py <snapshot> <event_json> <output_snapshot>

# Replay trace
python3 replay.py <base_snapshot> <trace_jsonl> <output_snapshot>

# Materialize from IR
python3 materialize.py <ir_json> <output_snapshot>
```

## Tests

```bash
bash runtime/world/lifecycle-tests.sh
bash runtime/world/replay-check.sh
```

## Determinism Invariant

Replaying the same event stream over the same initial state **must** produce identical snapshots. If hashes diverge, the lifecycle is invalid.
