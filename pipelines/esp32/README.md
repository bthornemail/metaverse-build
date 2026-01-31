# Phase 20A — ESP32 POSIX Projection

Goal: prove that only authority-validated messages reach an embedded subscriber via POSIX transports.

## Files
- `phase20A-run.sh` — PASS/FAIL transcript runner (POSIX bus)
- `serial-monitor.sh` — optional serial monitor for ESP32 output

## Run (host-only)
```bash
./metaverse-build/pipelines/esp32/phase20A-run.sh
```

## Run with ESP32 serial monitor
```bash
TTY=/dev/ttyUSB0 ./metaverse-build/pipelines/esp32/phase20A-run.sh
```

Expected:
- PASS writes to FIFO
- FAIL halts with `HALT: no publish` and writes nothing

AuthorityGate remains upstream and unchanged.
