# PubSub Runtime

Status: **extracted (frozen)** - Needs reimplementation

## Overview

PubSub provides topic-based message distribution. This is a stub module that requires reimplementation behind the authority gate.

## Capability

- Authority: universal-life-protocol
- Semantic Language: TypeScript/JavaScript

## Sources

- `sources/blackboard-web-README.md` - Reference implementation

## Contract

- Topics are named channels
- Publishers post to topics
- Subscribers receive from topics
- No guaranteed delivery (best-effort)

## Status

This module is in "extracted" status - the capability has been identified but the implementation needs to be rebuilt with proper authority gating.

## Next Steps

1. Reimplement pubsub semantics behind AuthorityGate
2. Ensure trace emission
3. Compile to World IR
4. Add deterministic message ordering
