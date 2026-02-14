# Shards Runtime

Distributed persistence and shard mobility system for zone state portability.

## Overview

A shard is a portable bundle containing zone state + trace + checkpoint. This enables offline mobility and integrity verification.

## Core Invariants

- Snapshot hash is canonical
- Trace hash is canonical  
- Restore verifies hashes before use
- No authority changes
- No mutation of trace during movement

## Files

- `bundle.py` - Creates shard bundles from zone data
- `restore.py` - Restores zone from shard bundle
- `shard-tests.sh` - Tests bundle creation and restore

## Bundle Layout

```
shard/<zone>/
  manifest.json
  zone.snapshot.json
  zone.trace.jsonl
  zone.checkpoint.json
```

## Usage

```bash
# Bundle a zone into a shard
python3 bundle.py <zone> <snapshot> <trace> <checkpoint> <output_dir>

# Restore from shard
python3 restore.py <shard_dir> <output_snapshot>
```

## Tests

```bash
bash runtime/shards/shard-tests.sh
```

## Non-Goals

- Live replication
- Conflict resolution
- Network transport

This phase is offline mobility + integrity checks only.
