# Trace Runtime

Status: **extracted (frozen)** - Needs reimplementation

## Overview

Trace provides event sequencing and logging. This is a stub module that requires reimplementation behind the authority gate.

## Capability

- Authority: universal-life-protocol
- Semantic Language: Shell

## Sources

- `sources/run.sh` - Trace runner

## Contract

- Events are sequenced
- Trace is append-only
- Each event has deterministic hash
- Trace enables replay

## Status

This module is in "extracted" status - the capability has been identified but the implementation needs to be rebuilt with proper authority gating.

## Next Steps

1. Reimplement trace semantics behind AuthorityGate
2. Ensure trace emission
3. Compile to World IR
4. Add deterministic event ordering
