# kernel-v1 (0.1.0)

kernel-v1 defines the minimal governed runtime for the metaverse build: a single AuthorityGate, approved pipelines, and explicit projection lanes. It is a **runtime profile**, not a feature set. UI, pubsub, and other projections are **non-authoritative** and must remain downstream of the gate.

MQTT was used as a projection experiment and is now superseded by native POSIX lattice transports.
