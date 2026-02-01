# Time Engine (Phase 35B)

A timeline is a DAG of checkpoints and event edges.

Core invariant:

```
checkpoint hash + trace window -> deterministic snapshot
```

This module defines:

- timeline object model
- branch primitive
- time address format
- window materialization

---

## Timeline Object

```json
{
  "world": "room",
  "timeline": "main",
  "nodes": {
    "ck-1": {"checkpoint": "...", "parent": null},
    "ck-2": {"checkpoint": "...", "parent": "ck-1"}
  }
}
```

Nodes reference checkpoint files; edges are parent links.

---

## Time Address

```
(world_id, timeline_id, checkpoint_id)
```

---

## Branch

```
branch(parent_checkpoint) -> new timeline id
```

- parent remains immutable
- new timeline reuses parent checkpoints

---

## Materialize

```
materialize(timeline, start_index, end_index) -> snapshot
```

Uses window replay over trace.

---

## Non-Goals

- UI rewind
- auto-merging timelines
- conflict resolution

This phase is the kernel time spine only.
