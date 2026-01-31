#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SDKCFG="$ROOT/firmware/esp32/esp-idf/sdkconfig.defaults"
DISC_CLIENT="$ROOT/pipelines/discovery/client.sh"

HOST="${DISCOVERY_HOST:-127.0.0.1}"
PORT="${DISCOVERY_PORT:-9333}"

set +e
RESP=$(HOST="$HOST" PORT="$PORT" bash "$DISC_CLIENT" 2>&1)
set -e
# Extract JSON line (first line with '{')
JSON_LINE=$(printf "%s" "$RESP" | awk 'match($0,/{/){print substr($0, RSTART); exit}' | sed 's/}[^}]*$/}/')
BROKER_URL=$(printf "%s" "$JSON_LINE" | sed -n 's/.*"mqtt":"\([^"]*\)".*/\1/p')

if [ -z "$BROKER_URL" ]; then
  echo "Failed to parse mqtt broker from discovery response" >&2
  exit 1
fi

# Update broker URL in sdkconfig.defaults
if grep -q '^CONFIG_BROKER_URL=' "$SDKCFG"; then
  sed -i "s|^CONFIG_BROKER_URL=.*|CONFIG_BROKER_URL=\"$BROKER_URL\"|" "$SDKCFG"
else
  echo "CONFIG_BROKER_URL=\"$BROKER_URL\"" >> "$SDKCFG"
fi

echo "Updated CONFIG_BROKER_URL to $BROKER_URL"
