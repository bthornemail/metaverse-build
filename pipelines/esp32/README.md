# Phase 20A — ESP32 MQTT Projection

Goal: prove that only authority-validated messages reach an embedded subscriber.

## Files
- `broker.sh` — starts local mosquitto broker
- `publish.sh` — authority-gated publish wrapper
- `subscribe-host.sh` — host subscriber (simulates ESP32)
- `serial-monitor.sh` — optional serial monitor for ESP32 output
- `phase20A-run.sh` — PASS/FAIL transcript runner

## Run (host-only)
```bash
./metaverse-build/pipelines/esp32/phase20A-run.sh
```

## Run with ESP32 serial monitor
```bash
TTY=/dev/ttyUSB0 ./metaverse-build/pipelines/esp32/phase20A-run.sh
```

Expected:
- PASS publishes a message on `metaverse/trace`
- FAIL halts with `HALT: no publish` and publishes nothing

AuthorityGate remains upstream and unchanged.
