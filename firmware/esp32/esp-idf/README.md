# ESP-IDF MQTT Subscriber (ESP32)

This ESP32 firmware subscribes to `metaverse/trace` and prints payloads to serial.

## Build/Flash (ESP-IDF)
```
idf.py set-target esp32
idf.py menuconfig
idf.py build
idf.py -p /dev/ttyUSB0 flash monitor
```

## Configure
Edit `sdkconfig.defaults` if needed:
- `CONFIG_ESP_WIFI_SSID`
- `CONFIG_ESP_WIFI_PASSWORD`
- `CONFIG_BROKER_URL`

Default broker is set to `mqtt://192.168.1.2:1883` (update to your host IP).

## Expected output
```
metaverse/trace <payload>
```

This device is a projection endpoint only; authority remains upstream in the Haskell gate.
