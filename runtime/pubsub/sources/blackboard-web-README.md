# Capability: PubSub
# Authority: universal-life-protocol
# Justification: ../JUSTIFICATION.md
# Inputs: MQTT topics/messages
# Outputs: pubsub propagation
# Trace: no
# ULP Blackboard Web (v2 scaffold)

Local-first web client built on the ULP v2 trace log. Adapters are swappable.

## Run (client)

npm install
npm run dev

## Relay

node relay/server.mjs

## Dotfiles

- world/.interrupt contains transport endpoints (MQTT/WS).

## MQTT Adapter

The browser client uses the WS endpoint from `world/.interrupt` when present.
MQTT presence is broadcast on `ulp/v2/presence` for peer discovery.
