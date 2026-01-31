# ESP-IDF TCP Bus Subscriber (ESP32)

This ESP32 firmware subscribes to the POSIX TCP bus and prints payloads to serial.

## Build/Flash (ESP-IDF)
```
idf.py set-target esp32
idf.py menuconfig
idf.py build
idf.py -p /dev/ttyUSB0 flash monitor
```

## Configure
Edit `sdkconfig.defaults` or use `menuconfig`:
- `CONFIG_ESP_WIFI_SSID`
- `CONFIG_ESP_WIFI_PASSWORD`
- `CONFIG_BUS_HOST`
- `CONFIG_BUS_PORT`

## Expected output
```
BUS <payload>
```

Authority remains upstream in the Haskell gate. This device is projection-only.
