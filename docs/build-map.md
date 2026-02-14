# Build Map

The build switchboard for metaverse-build - the canonical capability ledger.

## Overview

This file defines:
- Authority repo per capability
- Semantic language
- Invariant language
- Adapter languages
- Extraction status

## Identity & Trace

### Identity

- Authority Repo: tetragrammatron-os
- Semantic Language: YAML
- Adapter Languages: C
- Tooling: Python
- Status: extracted, frozen

### Authority-Projection

- Authority Repo: tetragrammatron-os
- Invariant Language: Haskell (executable)
- Adapter Languages: C
- Status: operational

### Trace

- Authority Repo: universal-life-protocol
- Semantic Language: Shell
- Adapter Languages: TypeScript/JavaScript
- Status: extracted, frozen

### Immutable-Log

- Authority Repo: bicf-production
- Semantic Language: Scheme (R5RS)
- Adapter Languages: Shell
- Status: extracted, frozen

### Replay

- Authority Repo: universal-life-protocol
- Semantic Language: Shell
- Adapter Languages: Scheme (R5RS)
- Status: extracted, frozen

## Runtime & Rendering

### 3D-Rendering

- Authority Repo: automaton
- Semantic Language: TypeScript
- Adapter Languages: TypeScript
- Status: extracted, frozen

### UI-Composition

- Authority Repo: automaton
- Semantic Language: TypeScript
- Adapter Languages: TypeScript
- Status: extracted, frozen

### User-Input

- Authority Repo: automaton
- Semantic Language: TypeScript
- Adapter Languages: TypeScript
- Status: extracted, frozen

## Formats

### CanvasL

- Authority Repo: bicf-production
- Semantic Language: Scheme (R5RS)
- Adapter Languages: TypeScript, Scheme (R5RS)
- Tooling: JSON schema

### JSONL

- Authority Repo: bicf-production
- Semantic Language: JSON
- Adapter Languages: Scheme (R5RS), TypeScript, JSONL

## Networking

### Sync

- Authority Repo: universal-life-protocol
- Semantic Language: TypeScript/JavaScript
- Adapter Languages: TypeScript
- Status: extracted, frozen

### PubSub

- Authority Repo: universal-life-protocol
- Semantic Language: TypeScript/JavaScript
- Status: extracted, frozen

### RPC

- Authority Repo: opencode-obsidian-agent
- Semantic Language: TypeScript
- Adapter Languages: TypeScript
- Status: extracted, frozen

## Tooling

### Code-Editor-Integration

- Authority Repo: opencode-obsidian-agent
- Semantic Language: TypeScript
- Adapter Languages: TypeScript
- Status: extracted, frozen

### Build-System

- Authority Repo: bicf-production
- Semantic Language: Shell
- Adapter Languages: Shell, TypeScript
- Tooling: Docker
- Status: extracted, frozen

## Kernel Layers

### Authority Gate

- Location: invariants/authority/
- Language: Haskell (pure, total, lazy)
- Status: enforced
- Role: halts invalid emission

### POSIX Bus

- Modes: FIFO, TCP
- Selection: lattice plan → bus.env
- MQTT: deprecated

### Lattice Plan Runtime

- Location: runtime/lattice/
- Function: peer discovery + basis routing
- Plan: content-addressed snapshots

### Projection Layer

- Location: projections/
- Authority: none
- Outputs: canvases, reports, history
- Git: ignored
