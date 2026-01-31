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

## POSIX bus slice
```
Trace → AuthorityGate → POSIX bus (FIFO/TCP) → subscriber (host/ESP32)
```
