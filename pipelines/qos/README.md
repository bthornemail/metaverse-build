# QoS Wrapper (Priority Lanes)

This wrapper applies per-branch QoS after the AuthorityGate. It never changes validity.

Modes:
- `fast`: no delay
- `smooth`: byte-rate limit via pv
- `slow`: per-line sleep via awk

Environment knobs:
- `QOS_BPS=50k` (smooth mode)
- `QOS_SLEEP=0.05` (slow mode)

Example:
```bash
QOS_BPS=10k QOS_SLEEP=0.10 ID_PREFIX=valid TRACE_INPUT="hello" \
  ./metaverse-build/pipelines/identity-trace-authority-fanout.sh
```
