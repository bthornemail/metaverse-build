# Phase 16A — Sync Adapter Behind Authority Gate

This adapter executes **only** on validated projections and has **no authority** over identity, trace, or state.

Wiring:
```
trace_producer | authority_gate | adapter_sync_runner | tee adapter.out
```

PASS:
```bash
ID_PREFIX=valid TRACE_INPUT="hello" ./metaverse-build/pipelines/identity-trace-authority-sync.sh
```

FAIL:
```bash
ID_PREFIX="" TRACE_INPUT="hello" ./metaverse-build/pipelines/identity-trace-authority-sync.sh
```

Expected:
- FAIL: gate halts, adapter is not invoked, no adapter.out
- PASS: adapter runs and emits output
