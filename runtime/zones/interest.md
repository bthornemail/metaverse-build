# Interest Management (Phase 32B)

Interest sets determine which spatial zones a client should load.

This phase defines a minimal deterministic interest model using spatial tiles.
Logical zones are overlays and do not influence spatial interest.

---

## Tile Naming

Spatial zones use the format:

```
"tile-X-Y"
```

Where X and Y are integers.

---

## Interest Rule

Given a center tile and radius R, the interest set is all tiles in the
square neighborhood:

```
[x-R, x+R] × [y-R, y+R]
```

Deterministic ordering is lexicographic by X then Y.

---

## Non-Goals

- Visibility culling
- Distance-based scoring
- Physics-driven interest

This is scaffolding only.
