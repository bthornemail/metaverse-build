# World IR

Intermediate Representation for world compilation.

## Overview

The World IR is the canonical intermediate representation that everything compiles into. It defines the minimal ontology that every world must compile into.

This is **not** rendering, physics, or gameplay - this is the structure of reality.

## Schema

See [world-ir/SCHEMA.md](../../world-ir/SCHEMA.md) for the full schema definition.

## Core Types

### World

Required: `world` (string)

Optional: `entities`, `zones`, `rules`, `portals`, `attachments`, `events`

### Entity

Required: `id`, `components`

Optional: `owner`, `zone`

### Component

Required: `type`

Optional: `data`

### Zone

Required: `id`

Optional: `bounds`, `tags`

### Attachment

Required: `id`, `target`, `kind`

Optional: `ref`

### Rule

Required: `id`, `guard`, `effect`

### Event

Required: `id`, `intent`

Optional: `authority`

### Portal

Required: `id`, `entry`

## Files

- `SCHEMA.md` - Schema documentation
- `ir.schema.json` - JSON schema
- `examples/minimal-world.json` - Minimal example
- `examples/room-with-entity.json` - Entity example
- `build/room.ir.json` - Built room IR
- `build/minimal.ir.json` - Built minimal IR
- `compiler/world-compile.sh` - IR compiler

## IR Compiler

```bash
bash world-ir/compiler/world-compile.sh <input> <output>
```

Compiles source definitions to World IR format.

## Examples

### Minimal World

```json
{
  "world": "minimal"
}
```

### Room with Entity

```json
{
  "world": "room",
  "entities": [
    {
      "id": "cube-001",
      "components": [
        { "type": "transform", "data": {"position": [0, 0, 0]} }
      ]
    }
  ]
}
```

## Constraints

- Worlds must be parseable and deterministic
- No implicit defaults beyond schema
- All authority is upstream of this IR
- This IR is the single target for compilation
