# RPC Runtime

Status: **extracted (frozen)** - Needs reimplementation

## Overview

RPC provides remote procedure call semantics. This is a stub module that requires reimplementation behind the authority gate.

## Capability

- Authority: opencode-obsidian-agent
- Semantic Language: TypeScript/JavaScript

## Sources

- `sources/opencode-README.md` - Reference implementation

## Adapters

- TypeScript/JavaScript (extracted, guarded)

## Contract

- Calls are request/response
- Requests are authenticated
- Responses are deterministic
- No guaranteed delivery (transport-dependent)

## Status

This module is in "extracted" status - the capability has been identified but the implementation needs to be rebuilt with proper authority gating.

## Next Steps

1. Reimplement RPC semantics behind AuthorityGate
2. Ensure trace emission
3. Compile to World IR
4. Add deterministic request handling
