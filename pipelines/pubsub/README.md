# Slice A — Trace → Authority → PubSub (FIFO)

Purpose: Prove authority gating before event bus projection.

Wiring:
```
trace_producer | authority_gate | tee pubsub.fifo
```

PASS:
```bash
ID_PREFIX=valid TRACE_INPUT="hello" ./metaverse-build/pipelines/pubsub/publish.sh
```

FAIL:
```bash
ID_PREFIX="" TRACE_INPUT="hello" ./metaverse-build/pipelines/pubsub/publish.sh
```

Statement: AuthorityProjection is enforced before transport.
