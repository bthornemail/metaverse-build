# Pipelines

End-to-end execution pipelines for the metaverse kernel.

## Overview

Pipelines are orchestration scripts that combine runtime components to achieve specific workflows. Each pipeline demonstrates a specific capability flow.

## Core Pipelines

### Identity-Trace-Authority

### Identity-Trace-Authority

- `identity-trace-authority-sync.sh` - Full identity trace flow with sync
- `identity-trace-authority-sync-rpc.sh` - With RPC
- `identity-trace-authority-sync-rpc-replay.sh` - With replay
- `identity-trace-authority-fanout.sh` - With fanout

### Log & Replay

- `identity-trace-log-replay.sh` - Log and replay pipeline

### Adapter Pipelines

- ` Chain adapter
adapter-chain/` -- `adapter-replay/` - Replay adapter
- `adapter-rpc/` - RPC adapter
- `adapter-sync/` - Sync adapter

### Discovery

- `discovery/` - Peer discovery
- `discovery/server.sh` - Discovery server
- `discovery/client.sh` - Discovery client
- `discovery/device-plan.sh` - Device plan

### ESP32

- `esp32/phase20A-run.sh` - Initial deployment
- `esp32/phase22A-run.sh` - Phase 22A
- `esp32/phase22C-run.sh` - Phase 22C
- `esp32/phase23-run.sh` - Phase 23
- `esp32/serial-monitor.sh` - Serial monitoring

### Lattice

- `lattice/phase23A-beacon-demo.sh` - Beacon demonstration

### Mind-Git

- `mind-git/run.sh` - Run mind-git pipeline
- `mind-git/export-vault.sh` - Export vault

### Network

- `network/send.sh` - Send message
- `network/listen.sh` - Listen for messages

### POSIX Bus

- `posix-bus/publish.sh` - Publish to bus
- `posix-bus/subscribe.sh` - Subscribe to bus
- `posix-bus/tcp/listen.sh` - TCP listen

### PubSub

- `pubsub/publish.sh` - Publish to topic
- `pubsub/subscribe.sh` - Subscribe to topic

### UI

- `ui/server.sh` - UI server
- `ui/publish.sh` - UI publish

### QoS

- `qos/qos.sh` - QoS handling

### Fanout

- `fanout/phase19A-run.sh` - Fanout phase 19A

## Running Pipelines

```bash
# Basic identity-trace-log-replay
ID_PREFIX=valid TRACE_INPUT="hello" ./pipelines/identity-trace-log-replay.sh

# Mind-git pipeline
bash pipelines/mind-git/run.sh
bash pipelines/mind-git/export-vault.sh
```

## Contract

All pipelines must:
1. Pass through AuthorityGate
2. Emit trace events
3. Be reproducible
