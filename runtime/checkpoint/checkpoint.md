# Checkpoint Kernel (Phase 33A)

Checkpoints are compression, not authority.

Core invariants:

```
replay(trace) == snapshot
snapshot(hash) is canonical
```

- Checkpoints never invent state.
- Checkpoints never mutate trace.
- Snapshot hash must be content-addressed and deterministic.
- Any mismatch is HALT: corruption.

---

## Checkpoint Format

```json
{
  "zone": "zone-a",
  "trace": "zone-a.trace.jsonl",
  "snapshot": "zone-a.snapshot.json",
  "last_index": 42,
  "snapshot_hash": "...",
  "timestamp": "2026-02-01T00:00:00Z"
}
```

---

## Algorithm

### checkpoint.py

1. Read trace
2. Apply events to base snapshot
3. Produce snapshot + hash
4. Emit checkpoint metadata

### restore.py

1. Read checkpoint
2. Load snapshot
3. Replay trace from `last_index+1`
4. Verify snapshot hash
5. HALT on mismatch

---

## Non-Goals

- Log pruning
- Rolling checkpoints
- Archival storage
- Timeline branching

These come after Phase 33A.
