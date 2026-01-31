# ESP32 Firmware (ESP-IDF)

This project uses **ESP-IDF** for the ESP32 projection endpoint.

Minimal behavior required:
- Connect Wi-Fi
- Subscribe to MQTT topic: `metaverse/trace`
- Print payload to serial (e.g., `metaverse/trace <payload>`)

Integration harness:
```
TTY=/dev/ttyUSB0 ./metaverse-build/pipelines/esp32/phase20A-run.sh
```

Status: placeholder for ESP-IDF project setup.
