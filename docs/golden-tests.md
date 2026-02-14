# Golden Tests

Deterministic replay verification using SHA256 hashes.

## Overview

Golden tests verify that the system produces deterministic, reproducible outputs. Each test has:
- Input fixture
- Expected hash
- Permuted fixture (same content, different order)

The permuted fixture ensures ordering invariance.

## Test Fixtures

### ULP Producer

- `mini.input.json` - Minimal input case
- `multi.input.json` - Multiple events
- `failure.input.json` - Failure case

Each has:
- `.input.json` - Original input
- `.replay-hash` - Expected SHA256 hash
- `.permuted.input.json` - Permuted version

## Running Tests

```bash
# Run all golden tests
bash scripts/golden-replay.sh

# Run specific test
bash scripts/golden-replay.sh \
  golden/ulp-producer/mini.input.json \
  golden/ulp-producer/mini.replay-hash \
  golden/ulp-producer/mini.permuted.input.json
```

## Contract

- Same content must produce same hash regardless of order
- Hash mismatch = test failure
- No external dependencies for verification
