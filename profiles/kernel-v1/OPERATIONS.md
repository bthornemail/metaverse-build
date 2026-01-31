# Operations

## PASS/FAIL fanout
```
ID_PREFIX=valid TRACE_INPUT="hello" ./metaverse-build/pipelines/identity-trace-authority-fanout.sh
ID_PREFIX="" TRACE_INPUT="hello" ./metaverse-build/pipelines/identity-trace-authority-fanout.sh
```

## Metrics mode
```
METRICS_N=10 METRICS_QOS_SLEEP=0.20 ./metaverse-build/pipelines/fanout/phase19A-run.sh metrics
```

## POSIX bus/ESP32 slice (host)
```
./metaverse-build/pipelines/esp32/phase20A-run.sh
```

## MQTT/ESP32 slice (with serial monitor)
```
TTY=/dev/ttyUSB0 ./metaverse-build/pipelines/esp32/phase20A-run.sh
```

## Lattice discovery (host)
```
metaverse-build/pipelines/discovery/server.sh
```

## Lattice discovery (client)
```
HOST=<discovery-host> metaverse-build/pipelines/discovery/client.sh
```

## Update ESP32 broker via discovery
```
DISCOVERY_HOST=<discovery-host> metaverse-build/pipelines/esp32/update-broker.sh
```
