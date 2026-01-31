# POSIX TCP Bus Listener

Projection-only TCP listener for the POSIX bus.

Reads bus env from `pipelines/posix-bus/bus.env` and listens on `BUS_TCP` port.

Idempotent behavior:
- If pidfile exists and process is alive → no-op

Outputs:
- `pipelines/posix-bus/tcp/state/trace.out`
