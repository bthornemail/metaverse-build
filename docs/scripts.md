# Scripts

Utility scripts for the metaverse kernel.

## Golden Replay Tests

```bash
# Run all golden tests
bash scripts/golden-replay.sh

# Run specific golden test
bash scripts/golden-replay.sh <fixture> <expected-hash-file> <permuted-fixture>
```

Golden tests verify deterministic replay using SHA256 hashes.

### Test Fixtures

- `golden/ulp-producer/mini.input.json` - Mini input
- `golden/ulp-producer/mini.replay-hash` - Expected hash
- `golden/ulp-producer/mini.permuted.input.json` - Permuted input (same content, different order)
- Similar for `multi.input.json` and `failure.input.json`

## Port Matroid Integration

```bash
# Append to port matroid store
scripts/append-to-port-matroid.sh <fixture> <store>
```

## Seam Envelopes

```bash
# Emit seam envelopes
python3 scripts/emit-seam-envelopes.py
```

Outputs seam envelopes for system integration.
