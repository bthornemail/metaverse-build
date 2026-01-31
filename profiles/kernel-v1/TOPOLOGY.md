# Topology

## Linear chain
```
Trace → AuthorityGate → Sync → RPC → Replay
```

## Fan-out
```
Trace → AuthorityGate →
  Chain A: Sync → RPC → Replay
  Chain B: PubSub (FIFO/MQTT)
  Chain C: UI stream
```

## MQTT projection slice
```
Trace → AuthorityGate → MQTT publish → subscriber (host/ESP32)
```
