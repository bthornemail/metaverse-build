---
type: contract
capability: [[dev-vault/Capabilities/Code-Editor-Integration|Code-Editor-Integration]]
authority: opencode-obsidian-agent
status: frozen
---

# Contract: Code-Editor-Integration

## Purpose
Editor integration for authoring.

## Inputs
- Vault files.

## Outputs
- Plugin runtime + CLI tooling.

## Invariants
- Runtime and plugin must agree on schema.

## Failure Modes
- No rendering or runtime execution.

## Extraction Target
metaverse-build/tooling/editor/

## Traceability
- [[dev-vault/Capabilities/Code-Editor-Integration|Code-Editor-Integration]]
- [[dev-vault/MOCs/Extraction-Plan]]
- [[dev-vault/MOCs/Capability-Evidence]]

## Unresolved Dependencies
- RPC transport details not extracted.
