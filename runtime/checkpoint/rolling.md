# Rolling Checkpoints (Phase 33B)

Rolling checkpoints keep a bounded window of snapshots and support replay of a
specific trace window without mutating the trace.

---

## Concepts

- **Checkpoint**: canonical snapshot + metadata derived from trace.
- **Window replay**: reconstruct state by replaying a slice of trace indices.
- **Pruning**: delete checkpoint files outside a retention window.

---

## Non-Goals

- Log compaction
- Timeline branching
- Delta compression

This phase adds bounded retention and replay windows only.
