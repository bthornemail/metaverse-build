# Checkpoint Runtime

The checkpoint system provides deterministic state snapshots with content-addressed hashing.

## Core Invariants

```
replay(trace) == snapshot
snapshot(hash) is canonical
```

- Checkpoints never invent state
- Checkpoints never mutate trace
- Snapshot hash must be content-addressed and deterministic
- Any mismatch triggers HALT: corruption

## Files

- `checkpoint.py` - Creates checkpoints from trace + base snapshot
- `restore.py` - Restores state from checkpoint
- `rolling-checkpoint.py` - Manages rolling checkpoint chains
- `prune.py` - Prunes old trace data
- `window-replay.py` - Replays a time window from trace

## Checkpoint Format

```json
{
  "zone": "zone-a",
  "trace": "zone-a.trace.jsonl",
  "snapshot": "zone-a.snapshot.json",
  "last_index": 42,
  "snapshot_hash": "sha256...",
  "timestamp": "2026-02-01T00:00:00Z"
}
```

## Usage

```bash
# Create checkpoint
python3 checkpoint.py <zone> <base_snapshot> <trace> <out_snapshot> <out_checkpoint>

# Restore from checkpoint
python3 restore.py <checkpoint> <trace> <out_snapshot>
```

## Tests

```bash
bash runtime/checkpoint/checkpoint-tests.sh
bash runtime/checkpoint/rolling-tests.sh
```

## Rolling Checkpoints

Rolling checkpoints keep a bounded window of snapshots and support replay of a specific trace window without mutating the trace.

### Concepts

- **Checkpoint**: canonical snapshot + metadata derived from trace
- **Window replay**: reconstruct state by replaying a slice of trace indices
- **Pruning**: delete checkpoint files outside a retention window

### Non-Goals

- Log compaction
- Timeline branching
- Delta compression

This phase adds bounded retention and replay windows only.
