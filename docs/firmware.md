# Firmware

ESP32 firmware for projection endpoints.

## ESP32 (ESP-IDF)

The firmware is a projection endpoint that:
1. Connects to Wi-Fi
2. Subscribes to POSIX bus topic
3. Prints payload to serial

### Goal

Prove that only authority-validated messages reach an embedded subscriber via POSIX transports.

### Build Requirements

- ESP-IDF toolchain
- ESP32 hardware

### Run (host-only)

```bash
./pipelines/esp32/phase20A-run.sh
```

### Run with ESP32 serial monitor

```bash
TTY=/dev/ttyUSB0 ./pipelines/esp32/phase20A-run.sh
```

Expected:
- PASS writes to FIFO
- FAIL halts with `HALT: no publish` and writes nothing

### Available Phases

- `phase20A-run.sh` - Initial deployment (Phase 20A)
- `phase22A-run.sh` - Phase 22A
- `phase22C-run.sh` - Phase 22C
- `phase23-run.sh` - Phase 23
- `serial-monitor.sh` - Monitor serial output

## Contract

Firmware is a downstream projection only. It:
1. Receives trace from bus
2. Outputs to serial
3. Has no authority
4. Cannot bypass AuthorityGate
