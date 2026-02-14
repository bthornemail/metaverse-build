# Time Runtime

Timeline engine providing branching and time-window materialization.

## Overview

A timeline is a DAG of checkpoints and event edges.

Core invariant:
```
checkpoint hash + trace window -> deterministic snapshot
```

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

## Time Address

```
(world_id, timeline_id, checkpoint_id)
```

## Files

- `branch.py` - Create branch from checkpoint
- `materialize.py` - Materialize time window to snapshot
- `time-tests.sh` - Time engine tests
- `merge-tests.sh` - Timeline merge tests

## Usage

```bash
# Create branch
python3 branch.py <timeline.json> <checkpoint_id> <output_timeline>

# Materialize window
python3 materialize.py <checkpoint> <trace> <start_index> <end_index> <output_snapshot>
```

## Tests

```bash
bash runtime/time/time-tests.sh
bash runtime/time/merge-tests.sh
```

## Non-Goals

- UI rewind
- auto-merging timelines
- conflict resolution

This phase is the kernel time spine only.

## Timeline Merge (Phase 36)

Merges are legal only when they preserve deterministic replay and authority.

### Core Rule

```
merge(A, B) is allowed only if replay(genesis, A) == replay(genesis, B)
```

This is stricter than Git. It is intentional.

### Timeline Types

- `canonical`: authoritative history
- `speculative`: sandbox branch
- `local`: editor-only branch

Only `speculative` or `local` may merge into `canonical`, and only if the resulting snapshot hash matches across all peers.

### Merge Gate

A merge is allowed if:
1. both timelines share the same world
2. candidate checkpoints are valid (hash verified)
3. snapshot hashes are identical

If any check fails: **HALT: MergeDenied**.
