# Timeline Merge Semantics (Phase 36)

Merges are legal only when they preserve deterministic replay and authority.

Core rule:

```
merge(A, B) is allowed only if replay(genesis, A) == replay(genesis, B)
```

This is stricter than Git. It is intentional.

---

## Timeline Types

- `canonical`: authoritative history
- `speculative`: sandbox branch
- `local`: editor-only branch

Only `speculative` or `local` may merge into `canonical`, and only if the
resulting snapshot hash matches across all peers.

---

## Merge Gate

A merge is allowed if:

1. both timelines share the same world
2. candidate checkpoints are valid (hash verified)
3. snapshot hashes are identical

If any check fails: **HALT: MergeDenied**.

---

## Non-Goals

- auto-resolving conflicts
- partial state merges
- CRDT behavior

These violate deterministic replay.
