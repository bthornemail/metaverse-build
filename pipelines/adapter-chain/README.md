# Adapter Chain — Sync → RPC → Replay (Single AuthorityGate)

This pipeline demonstrates linear adapter composition under a single AuthorityGate. Authority is centralized, non-reentrant, and enforced before any adapter executes.

Wiring:
```
trace_producer | authority_gate | adapter_sync | adapter_rpc | adapter_replay | tee chain3.out
```

PASS:
```bash
ID_PREFIX=valid TRACE_INPUT="hello" ./metaverse-build/pipelines/identity-trace-authority-sync-rpc-replay.sh
```

FAIL:
```bash
ID_PREFIX="" TRACE_INPUT="hello" ./metaverse-build/pipelines/identity-trace-authority-sync-rpc-replay.sh
```

Expected:
- FAIL: gate halts, no adapter execution, no chain3.out
- PASS: Sync → RPC → Replay runs, output emitted
