# Distributed Persistence + Shard Mobility (Phase 34)

A shard is a portable bundle of zone state + trace + checkpoint.

This module defines:

- bundle format (manifest + files)
- deterministic hash verification
- mobility simulation (copy bundle between nodes)

## Invariants

- Snapshot hash is canonical
- Trace hash is canonical
- Restore verifies hashes before use
- No authority changes
- No mutation of trace during movement

## Bundle Layout

```
shard/<zone>/
  manifest.json
  zone.snapshot.json
  zone.trace.jsonl
  zone.checkpoint.json
```

## Non-Goals

- Live replication
- Conflict resolution
- Network transport

This phase is offline mobility + integrity checks only.
