---
type: justification
capability: [[dev-vault/Capabilities/Code-Editor-Integration|Code-Editor-Integration]]
authority: opencode-obsidian-agent
status: frozen
---

# Capability Justification: Code-Editor-Integration

## Purpose
Obsidian-native authoring and agent runtime tooling.

## Authority
opencode-obsidian-agent is authoritative for Obsidian plugin + CLI.

## Inputs
- Vault files.

## Outputs
- Plugin runtime + CLI scaffolding.

## Invariants
- Vault structure must be consistent with runtime.

## Failure Modes
- Does not define metaverse runtime semantics.

## Extraction Target
metaverse-build/tooling/editor/

## Traceability
- [[dev-vault/Capabilities/Code-Editor-Integration|Code-Editor-Integration]]
- [[dev-vault/Repos/opencode-obsidian-agent|opencode-obsidian-agent]]
- /home/main/devops/opencode-obsidian-agent/README.md
