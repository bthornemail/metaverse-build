# AGENTS.md - Metaverse Build Runtime

This file provides guidance for agentic coding agents operating in this repository.

## Project Overview

The Metaverse Build Runtime is a **capability kernel** that enforces the core invariant: **Identity → Authority → Trace → Projection**. It is not a feature repo - all capabilities exist to enforce this contract.

### Key Directories

- `invariants/authority/` - Haskell executable invariants (authority gate)
- `runtime/` - Core runtime components (time, shards, checkpoint, zones, sync, world, lattice)
- `pipelines/` - End-to-end pipeline executions
- `capabilities/` - Extracted capability stubs
- `formats/` - Data format definitions (CanvasL, JSONL)
- `tooling/` - Editor integration tools
- `firmware/` - ESP32 firmware (C)
- `scripts/` - Utility scripts
- `golden/` - Golden test fixtures with expected hashes

## Build, Lint, and Test Commands

### Haskell (Authority Invariants)

```bash
# Build with Cabal
cd invariants/authority
cabal build

# Run tests
cabal test

# Run a single test (Spec.hs)
cabal run authority-tests
# Or directly:
runhaskell tests/Spec.hs
```

### Shell Scripts (Most Tests)

All shell tests use `set -euo pipefail`. Run individual test scripts:

```bash
# Time engine tests
bash runtime/time/time-tests.sh
bash runtime/time/merge-tests.sh

# Shard tests
bash runtime/shards/shard-tests.sh

# Checkpoint tests
bash runtime/checkpoint/checkpoint-tests.sh
bash runtime/checkpoint/rolling-tests.sh

# Zone tests
bash runtime/zones/zone-tests.sh
bash runtime/zones/authority-tests.sh
bash runtime/zones/interest-tests.sh
bash runtime/zones/migration-tests.sh

# Transport tests
bash runtime/sync-transport/transport-tests.sh

# Editor tests
bash editor/editor-tests.sh

# World lifecycle tests
bash runtime/world/lifecycle-tests.sh

# Run a single test (e.g., time-tests)
cd runtime/time && bash time-tests.sh
```

### Golden Replay Tests

```bash
# Run all golden tests
bash scripts/golden-replay.sh

# Run specific golden test
bash scripts/golden-replay.sh <fixture> <expected-hash-file> <permuted-fixture>
```

### Pipeline Execution

```bash
# Run specific pipeline
bash pipelines/mind-git/run.sh
bash pipelines/esp32/phase20A-run.sh

# Export vault (operator cockpit)
bash pipelines/mind-git/export-vault.sh
```

### Python Scripts

```bash
# Run Python scripts directly
python3 runtime/checkpoint/checkpoint.py <zone> <base_snapshot> <trace> <out_snapshot> <out_checkpoint>
python3 runtime/time/branch.py <timeline> <checkpoint_id> <output>
python3 runtime/time/materialize.py <checkpoint> <trace> <start> <end> <output>
```

## Code Style Guidelines

### Haskell

- **Formatting**: 2-space indentation, no tabs
- **Module declarations**: Explicit exports in parentheses
- **Naming**: CamelCase for types and functions, snake_case rarely used
- **Comments**: Header comment with capability metadata (Authority, Inputs, Outputs, Trace)
- **Error handling**: Use `Either` for validation, return `Left` on failure
- **Types**: Use `newtype` for opaque wrappers, derive Eq/Show where appropriate
- **Imports**: Explicit imports, one per line

```haskell
-- Capability: Authority-Projection
-- Authority: tetragrammatron-os
-- Justification: ../INVARIANT.md

module AuthorityProjection
  ( AuthorityViolation(..)
  , Identity(..)
  , Trace(..)
  ) where

newtype Identity = Identity { identityPrefix :: String }
  deriving (Eq, Show)

validateAuthority :: Identity -> Trace -> Either AuthorityViolation ValidatedTrace
validateAuthority ident tr = ...
```

### Shell Scripts

- **Shebang**: `#!/usr/bin/env bash` (or python3 for Python scripts)
- **Error handling**: Always use `set -euo pipefail`
- **Indentation**: 2 spaces
- **Variables**: UPPERCASE for constants, lowercase for locals
- **Functions**: Define with `name() { ... }` syntax
- **Quotes**: Use double quotes for variable expansion, single quotes for literals

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

main() {
  local input="$1"
  # ...
}
```

### Python

- **Shebang**: `#!/usr/bin/env python3`
- **Style**: Follow PEP 8 where practical
- **Indentation**: 2 spaces (matching project style)
- **Functions**: snake_case
- **Error handling**: Print to stderr and `sys.exit(2)` for usage errors

```python
#!/usr/bin/env python3
import json
import sys

def fail(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)

if len(sys.argv) < 3:
    fail("usage: script.py <input> <output>")
```

### C (Firmware)

- **Style**: Linux kernel style
- **Indentation**: 2 spaces, no tabs
- **Types**: Use typedefs for opaque types
- **Error handling**: ESP_ERROR_CHECK macro for ESP-IDF
- **Logging**: Use ESP_LOG* macros with TAG defined per file

```c
// Capability: TCP bus subscriber
// Authority: AuthorityGate

#include <stdio.h>

#define TAG "metaverse-esp32"

static void foo(void) {
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));
    ESP_LOGI(TAG, "Initialized");
}
```

### TypeScript / JavaScript

Not currently present in this repository, but if added:
- Use TypeScript for new code
- 2-space indentation
- Explicit types
- ESM modules

### JSON / JSONL

- 2-space indentation
- No trailing commas

## Key Conventions

1. **Capability Headers**: Every capability file should have a header comment:
   - Capability name
   - Authority source
   - Justification reference
   - Inputs/Outputs
   - Trace: yes/no
   - Halt-On-Violation status

2. **Test Output**: Tests output `PASS` or `FAIL` with test name. Exit code 0 for success.

3. **Golden Tests**: Use golden files with SHA256 hashes for deterministic verification.

4. **Reports**: Test reports go in `reports/` directory with phase naming (e.g., `phase35B-time.txt`).

5. **State**: Runtime state goes in `runtime/<component>/state/` directories.

6. **Authority Gate**: All emission must pass through `AuthorityGate`. Violations result in HALT with zero bytes emitted.

## Running a Single Test

```bash
# Haskell test
cd invariants/authority && runhaskell tests/Spec.hs

# Shell test
bash runtime/time/time-tests.sh

# Specific golden test
bash scripts/golden-replay.sh \
  golden/ulp-producer/mini.input.json \
  golden/ulp-producer/mini.replay-hash \
  golden/ulp-producer/mini.permuted.input.json
```

## Important Notes

- The authority gate is enforced in `invariants/authority/gate/AuthorityGate.hs`
- The runtime uses FIFO/TCP for POSIX bus transport (no MQTT)
- Plans are content-addressed snapshots
- Projection artifacts are disposable and git-ignored
- All adapters are downstream projections only
