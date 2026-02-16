# ESP32-S3 Metaverse Node

The ESP32-S3 serves as an edge device that connects physical sensors to the virtual metaverse with full authority validation.

## Hardware

- **ESP32-S3** - Dual-core Xtensa LX7 @ 240MHz
- **512KB SRAM** + external PSRAM
- **WiFi 2.4GHz** 802.11 b/g/n
- **Bluetooth 4.2**

Perfect for: 16KB binary + network stack

## Architecture

```
┌─────────────┐      WiFi       ┌─────────────┐
│  ESP32-S3  │───────────────▶│   Laptop    │
│  (Edge)    │   1-10/sec     │  (Core)     │
│            │◀───────────────│             │
│ Sensors    │   Commands     │ 70K/sec    │
└─────────────┘                └─────────────┘
```

## ESP32 Code

The ESP32 runs a simplified authority validation that matches the C core:

```c
// Ultra-fast validation (matches C native core)
int validate_authority(const char* actor, const char* entity) {
    return strncmp(actor, "valid:", 6) == 0;
}
```

## Laptop Server

The laptop runs the full C native gate (70K/sec capable):

```bash
# Run world server
python3 laptop_world_server.py
```

## Expected Performance

| Component | Rate |
|-----------|------|
| ESP32 Validation | 50K/sec |
| WiFi Transmission | 1-10/sec |
| Laptop Processing | 70K/sec |

## Setup

1. Install ESP-IDF
2. Configure WiFi credentials
3. Build and flash
4. Run laptop server
5. Watch ESP32 appear in virtual world
