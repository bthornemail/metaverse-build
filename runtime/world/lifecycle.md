# World State Lifecycle

This document defines the minimal mutation grammar for world state.

The lifecycle is the only allowed change surface.
All higher-level features must compile to these operations.

---

## Event Grammar (Only Six)

### 1. ENTITY_CREATE
Create a persistent entity.

```
{ "type": "ENTITY_CREATE", "id": "entity-id", "owner": "valid:userA", "actor": "valid:userA", "internal": "eN" }
```

- `id` is required
- `owner` is required
- `actor` is required
- `internal` is optional (deterministic assignment if omitted)

---

### 2. ENTITY_DESTROY
Remove an entity.

```
{ "type": "ENTITY_DESTROY", "id": "entity-id", "actor": "valid:userA" }
```

---

### 3. COMPONENT_ATTACH
Attach a component to an entity.

```
{ "type": "COMPONENT_ATTACH", "entity": "entity-id", "component": "transform", "cid": "e1.c1", "data": { ... }, "actor": "valid:userA" }
```

- `entity` and `component` are required
- `cid` optional (deterministic assignment if omitted)
- `data` optional

---

### 4. COMPONENT_UPDATE
Update a component’s data.

```
{ "type": "COMPONENT_UPDATE", "entity": "entity-id", "component": "transform", "patch": { ... }, "actor": "valid:userA" }
```

- `patch` is shallow-merged into component data

---

### 5. COMPONENT_DETACH
Remove a component from an entity.

```
{ "type": "COMPONENT_DETACH", "entity": "entity-id", "component": "transform", "actor": "valid:userA" }
```

---

### 6. ZONE_MOVE
Move entity to a zone.

```
{ "type": "ZONE_MOVE", "entity": "entity-id", "zone": "zone-id", "actor": "valid:userA" }
```

---

## Authority Semantics

- Every entity has an immutable `owner`.
- Every mutating event must include an `actor`.
- If `actor != owner` for the target entity → **HALT**.
- `ENTITY_CREATE` must include `owner` and `actor`.
- In v0, `owner` may be set to a value different from `actor` on create.
- Missing `actor` or `owner` → **HALT**.

HALT behavior:

- state unchanged
- snapshot hash unchanged
- interpreter returns explicit halt result

---

## Interpreter Rule

```
state + event → new state
```

- pure function
- no IO
- deterministic
- replayable

---

## Determinism Invariant

Replaying the same event stream over the same initial state **must** produce identical snapshots.

If hashes diverge, the lifecycle is invalid.
