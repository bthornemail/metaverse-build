# Slice D — Trace → Authority → MQTT (ESP32 Projection)

Purpose: Prove authority gating before MQTT publish to a constrained subscriber.

Wiring:
```
trace_producer | authority_gate | mqtt_publish (topic: metaverse/trace)
```

PASS:
```bash
ID_PREFIX=valid TRACE_INPUT="hello" ./metaverse-build/pipelines/mqtt/publish.sh
```

FAIL:
```bash
ID_PREFIX="" TRACE_INPUT="hello" ./metaverse-build/pipelines/mqtt/publish.sh
```

Subscriber:
```bash
./metaverse-build/pipelines/mqtt/subscribe.sh
```

Statement: AuthorityProjection is enforced before publish.
