# Slice B — Trace → Authority → Network (netcat)

Purpose: Prove authority gating before network emission.

Wiring:
```
trace_producer | authority_gate | nc localhost 9000
```

PASS:
```bash
PORT=9000 ID_PREFIX=valid TRACE_INPUT="hello" ./metaverse-build/pipelines/network/send.sh
```

FAIL:
```bash
PORT=9000 ID_PREFIX="" TRACE_INPUT="hello" ./metaverse-build/pipelines/network/send.sh
```

Statement: AuthorityProjection is enforced before transport.
