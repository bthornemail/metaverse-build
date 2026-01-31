# Thin POSIX Integration Slice

Identity → Trace → Immutable-Log → Replay with a Haskell authority gate in the pipe.

Run:

```bash
ID_PREFIX=valid TRACE_INPUT="hello" ./pipelines/identity-trace-log-replay.sh
```

FAIL case (must halt before log/replay):

```bash
ID_PREFIX="" TRACE_INPUT="hello" \
  ./metaverse-build/pipelines/identity-trace-log-replay.sh
```

Expected:
- stderr: "HALT: InvalidSchemaPrefix"
- exit code != 0
- no trace.log written
- no replay output

Notes:
- This uses the executable invariant gate (`AuthorityGate.hs`) and halts on violation.
- No adapters or runtime integrations are invoked.
- Replay is best-effort and may be a no-op depending on decoder expectations.
