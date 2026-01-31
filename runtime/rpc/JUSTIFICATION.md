---
type: justification
capability: [[dev-vault/Capabilities/RPC|RPC]]
authority: opencode-obsidian-agent
status: frozen
---

# Capability Justification: RPC

## Purpose
Local RPC server for Obsidian agent runtime.

## Authority
opencode-obsidian-agent defines runtime + plugin RPC.

## Inputs
- RPC requests.

## Outputs
- RPC responses.

## Invariants
- Runtime and plugin must agree on protocol.

## Failure Modes
- Does not define network discovery.

## Extraction Target
metaverse-build/runtime/rpc/

## Traceability
- [[dev-vault/Capabilities/RPC|RPC]]
- [[dev-vault/Repos/opencode-obsidian-agent|opencode-obsidian-agent]]
- /home/main/devops/opencode-obsidian-agent/README.md
