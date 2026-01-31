# Slice C — Trace → Authority → UI Stream (HTTP over nc)

Purpose: Prove authority gating before UI projection.

Wiring:
```
trace_producer | authority_gate | tee ui.stream
```

PASS:
```bash
ID_PREFIX=valid TRACE_INPUT="hello" ./metaverse-build/pipelines/ui/publish.sh
```

FAIL:
```bash
ID_PREFIX="" TRACE_INPUT="hello" ./metaverse-build/pipelines/ui/publish.sh
```

Statement: AuthorityProjection is enforced before transport.
