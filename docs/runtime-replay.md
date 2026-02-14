# Replay Runtime

Status: **extracted (frozen)** - Needs reimplementation

## Overview

Replay provides deterministic event replay from trace. This is a stub module that requires reimplementation behind the authority gate.

## Capability

- Authority: universal-life-protocol
- Semantic Language: Shell
- Adapter Languages: Scheme (R5RS)

## Sources

- `sources/decode_trace.sh` - Trace decoder

## Contract

- Replay is deterministic
- Same trace always produces same state
- Replay can start from any checkpoint
- Hash verification ensures integrity

## Status

This module is in "extracted" status - the capability has been identified but the implementation needs to be rebuilt with proper authority gating.

## Next Steps

1. Reimplement replay semantics behind AuthorityGate
2. Ensure trace emission
3. Compile to World IR
4. Add deterministic checkpoint selection
