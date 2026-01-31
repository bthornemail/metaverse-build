# World State Lifecycle

This document defines the minimal mutation grammar for world state.

The lifecycle is the only allowed change surface.
All higher-level features must compile to these operations.

---

## Event Grammar (Only Six)

### 1. ENTITY_CREATE
Create a persistent entity.

```
{ "type": "ENTITY_CREATE", "id": "entity-id", "internal": "eN" }
```

- `id` is required
- `internal` is optional (deterministic assignment if omitted)

---

### 2. ENTITY_DESTROY
Remove an entity.

```
{ "type": "ENTITY_DESTROY", "id": "entity-id" }
```

---

### 3. COMPONENT_ATTACH
Attach a component to an entity.

```
{ "type": "COMPONENT_ATTACH", "entity": "entity-id", "component": "transform", "cid": "e1.c1", "data": { ... } }
```

- `entity` and `component` are required
- `cid` optional (deterministic assignment if omitted)
- `data` optional

---

### 4. COMPONENT_UPDATE
Update a component’s data.

```
{ "type": "COMPONENT_UPDATE", "entity": "entity-id", "component": "transform", "patch": { ... } }
```

- `patch` is shallow-merged into component data

---

### 5. COMPONENT_DETACH
Remove a component from an entity.

```
{ "type": "COMPONENT_DETACH", "entity": "entity-id", "component": "transform" }
```

---

### 6. ZONE_MOVE
Move entity to a zone.

```
{ "type": "ZONE_MOVE", "entity": "entity-id", "zone": "zone-id" }
```

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
