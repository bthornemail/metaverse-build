# World IR Schema

This document defines the minimal ontology that every world must compile into.

This is **not** rendering, physics, or gameplay.
This is the structure of reality.

---

## Core Types

### World

Required:
- `world` (string): world identifier

Optional:
- `entities` (array of Entity)
- `zones` (array of Zone)
- `rules` (array of Rule)
- `portals` (array of Portal)
- `attachments` (array of Attachment)
- `events` (array of Event)

---

### Entity

Required:
- `id` (string): persistent identity
- `components` (array of Component)

Optional:
- `owner` (string): authority boundary identifier
- `zone` (string): zone id

---

### Component

Required:
- `type` (string)

Optional:
- `data` (object)

Components are typed slots for data and behavior.

---

### Zone

Required:
- `id` (string)

Optional:
- `bounds` (object)
- `tags` (array of string)

Zones are spatial or logical partitions.

---

### Attachment

Required:
- `id` (string)
- `target` (string): entity id
- `kind` (string)

Optional:
- `ref` (string): asset reference

Attachments bind assets or behaviors to entities.

---

### Rule

Required:
- `id` (string)
- `guard` (object)
- `effect` (object)

Rules are guard → effect transforms that emit trace events.

---

### Event

Required:
- `id` (string)
- `intent` (object)

Optional:
- `authority` (string)

Events represent intent that becomes trace-validated state change.

---

### Portal

Required:
- `id` (string)
- `entry` (object)

Portals are projection boundaries.

---

## Constraints

- Worlds must be parseable and deterministic.
- No implicit defaults beyond this schema.
- All authority is upstream of this IR.
- This IR is the single target for compilation.

---

## Notes

This schema is minimal by design.
Do not add simulation features here.
Those belong in downstream projections.
