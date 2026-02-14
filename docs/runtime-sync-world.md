# Sync World Runtime

Multiplayer synchronization using deterministic envelope ordering.

## Overview

The sync world system enables multi-peer ordering without clocks or conflict resolution. It defines a deterministic envelope that wraps lifecycle events.

## Envelope Shape

```json
{
  "peer": "peer-A",
  "seq": 12,
  "t": "2026-01-31T00:00:00Z",
  "event": { "type": "COMPONENT_UPDATE", ... }
}
```

- `peer` (string, required): sender identity
- `seq` (integer, required): monotonic per peer
- `t` (string, optional): timestamp (non-authoritative)
- `event` (object, required): lifecycle event object

## Ordering Rule

Deterministic total order:
1. `peer` (lexicographic ascending)
2. `seq` (numeric ascending)

No clocks. No Lamport. No vector clocks.

## Authority Rule

Authority remains local and deterministic:
- Each peer applies the same lifecycle interpreter
- If an event violates authority, the peer HALTs the event and preserves state
- The envelope remains in the log; it simply does not mutate state

## Files

- `append.sh` - Append event to envelope
- `merge.sh` - Merge envelopes from multiple peers
- `apply-merged.sh` - Apply merged envelopes to state
- `simulate-two-peers.sh` - Two-peer simulation

## Usage

```bash
# Append event
bash append.sh <peer> <event_json> <seq>

# Merge peer envelopes
bash merge.sh <peer_a_envelope> <peer_b_envelope> <output>

# Apply merged envelopes
bash apply-merged.sh <merged_envelopes> <snapshot>
```

## Tests

```bash
bash runtime/sync-world/simulate-two-peers.sh
```

## Non-Goals

- Live networking
- Conflict resolution heuristics
- CRDTs
- Signing / crypto identity

This is scaffolding for deterministic sync behavior only.
