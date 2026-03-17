#!/usr/bin/env python3
"""Deterministic Perles/Gray identity helpers for 3x3x3 agent geometry."""

from __future__ import annotations

from typing import Any, Dict, List, Sequence, Tuple


TIME_POINTS = 240
STATE_POINTS = 256
AGENT_POINTS = 27
CONTROL_CODES = 60

_GRID = 3
_CUBE = 4


class PerlesIdentityError(ValueError):
  pass


def _require_sid_hex(sid: str) -> str:
  if not isinstance(sid, str) or not sid.startswith("sha256:"):
    raise PerlesIdentityError("sid must be sha256:*")
  digest = sid.split(":", 1)[1]
  if len(digest) != 64 or any(ch not in "0123456789abcdef" for ch in digest):
    raise PerlesIdentityError("sid hex digest invalid")
  return digest


def perles_index_to_coord(index: int) -> Tuple[int, int, int]:
  if not isinstance(index, int) or not (0 <= index < AGENT_POINTS):
    raise PerlesIdentityError("index must be integer in [0, 26]")
  x = index % _GRID
  y = (index // _GRID) % _GRID
  z = index // (_GRID * _GRID)
  return (x, y, z)


def perles_coord_to_index(coord: Sequence[int]) -> int:
  if not isinstance(coord, (list, tuple)) or len(coord) != 3:
    raise PerlesIdentityError("coord must be a 3-tuple")
  x, y, z = int(coord[0]), int(coord[1]), int(coord[2])
  if not (0 <= x < _GRID and 0 <= y < _GRID and 0 <= z < _GRID):
    raise PerlesIdentityError("coord values must be in [0, 2]")
  return x + (_GRID * y) + (_GRID * _GRID * z)


def sid_to_perles_anchor(sid: str) -> Dict[str, Any]:
  digest = _require_sid_hex(sid)
  seed = int(digest[:12], 16)
  idx = seed % AGENT_POINTS
  local = perles_index_to_coord(idx)

  # Infinite tiling index in 3x3x3 blocks.
  tx = (seed >> 12) & 0xFF
  ty = (seed >> 20) & 0xFF
  tz = (seed >> 28) & 0xFF

  # "Agent at (3,3,3)" modeled as center-of-next-cube anchor for tile origin.
  # Global coordinates are 1-based centers of each local cube.
  global_coord = (
    (tx * _GRID) + local[0] + 1,
    (ty * _GRID) + local[1] + 1,
    (tz * _GRID) + local[2] + 1,
  )

  return {
    "sid": sid,
    "perles_index": idx,
    "local_coord": local,
    "tile_coord": (tx, ty, tz),
    "global_coord": global_coord,
    "center_reference": (3, 3, 3),
  }


def tension_signature(step: int) -> Dict[str, int]:
  if not isinstance(step, int) or step < 0:
    raise PerlesIdentityError("step must be integer >= 0")
  t = step % TIME_POINTS
  s = step % STATE_POINTS
  a = step % AGENT_POINTS

  # Pairwise misalignment in their own modular spaces.
  ts = abs((t % 16) - (s % 16))
  sa = abs((s % 27) - a)
  at = abs((a % 15) - (t % 15))
  tension = ts + sa + at

  return {
    "step": step,
    "time_phase": t,
    "state_phase": s,
    "agent_phase": a,
    "tension": tension,
    "ts": ts,
    "sa": sa,
    "at": at,
  }


def control_code_cube_model() -> Dict[str, Any]:
  # 4x4x4 has 64 vertices; model 60 codes as cube with 4 missing corners.
  corners = {
    (0, 0, 0),
    (0, 0, 3),
    (0, 3, 0),
    (3, 0, 0),
  }
  points: List[Tuple[int, int, int]] = []
  for z in range(_CUBE):
    for y in range(_CUBE):
      for x in range(_CUBE):
        p = (x, y, z)
        if p in corners:
          continue
        points.append(p)
  if len(points) != CONTROL_CODES:
    raise PerlesIdentityError("control-code cube model must contain exactly 60 points")
  return {
    "cube_size": _CUBE,
    "point_count": len(points),
    "missing_corners": sorted(corners),
    "points": points,
  }
