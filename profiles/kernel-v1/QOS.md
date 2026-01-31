# QoS Lanes

QoS is a projection property. It never changes validity.

Lanes:
- UI: fast
- PubSub: smooth (rate-limited)
- Chain A: slow (sleep-per-record)

Knobs:
- `QOS_BPS` (smooth mode, default 50k)
- `QOS_SLEEP` (slow mode, default 0.05)
