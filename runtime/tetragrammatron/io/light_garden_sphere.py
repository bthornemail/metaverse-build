#!/usr/bin/env python3
"""Deterministic lossless sphere encoding via frame-of-reference transforms."""

from __future__ import annotations

from itertools import permutations
from typing import Any, Dict, List, Sequence, Tuple


SCHEMA_V = "tetragrammatron.light_garden_sphere.v0"
POINT_COUNT = 60
DIM = 4
FRAME_COUNT = 240


class LightGardenSphereError(ValueError):
  pass


def _require_exact_keys(obj: Dict[str, Any], allowed: Sequence[str], label: str) -> None:
  got = set(obj.keys())
  expect = set(allowed)
  if got != expect:
    raise LightGardenSphereError(f"{label} keyset mismatch: expected={sorted(expect)} got={sorted(got)}")


def _validate_points(points: Sequence[Sequence[int]]) -> List[Tuple[int, int, int, int]]:
  if not isinstance(points, (list, tuple)) or len(points) != POINT_COUNT:
    raise LightGardenSphereError(f"points must contain exactly {POINT_COUNT} entries")
  out: List[Tuple[int, int, int, int]] = []
  for row in points:
    if not isinstance(row, (list, tuple)) or len(row) != DIM:
      raise LightGardenSphereError("each point must be a 4-tuple")
    vals = tuple(int(v) for v in row)
    out.append(vals)
  return out


def _frame_transforms() -> List[Tuple[Tuple[int, int, int, int], Tuple[int, int, int, int]]]:
  # 24 coordinate permutations x 10 sign patterns = 240 deterministic frames.
  perms = sorted(set(permutations((0, 1, 2, 3), 4)))
  signs: List[Tuple[int, int, int, int]] = []
  for bits in range(16):
    signs.append(tuple(-1 if ((bits >> i) & 1) else 1 for i in range(4)))
  signs = signs[:10]
  out: List[Tuple[Tuple[int, int, int, int], Tuple[int, int, int, int]]] = []
  for perm in perms:
    for sign in signs:
      out.append((perm, sign))
  if len(out) != FRAME_COUNT:
    raise LightGardenSphereError("internal frame transform cardinality mismatch")
  return out


_TRANSFORMS = _frame_transforms()


def _apply_transform(vec: Tuple[int, int, int, int], perm: Tuple[int, int, int, int], sign: Tuple[int, int, int, int]) -> Tuple[int, int, int, int]:
  return tuple(sign[i] * vec[perm[i]] for i in range(4))


def _invert_transform(vec: Tuple[int, int, int, int], perm: Tuple[int, int, int, int], sign: Tuple[int, int, int, int]) -> Tuple[int, int, int, int]:
  # y_i = s_i * x_perm_i => x_j = s_k * y_k where perm_k = j
  out = [0, 0, 0, 0]
  for i in range(4):
    j = perm[i]
    out[j] = sign[i] * vec[i]
  return tuple(out)


def compute_centroid(points: Sequence[Sequence[int]]) -> Dict[str, Any]:
  rows = _validate_points(points)
  sums = [0, 0, 0, 0]
  for p in rows:
    for i in range(4):
      sums[i] += p[i]
  return {
    "numerator": sums,
    "denominator": POINT_COUNT,
  }


def encode_frame(points: Sequence[Sequence[int]], frame_id: int) -> Dict[str, Any]:
  rows = _validate_points(points)
  if not isinstance(frame_id, int) or not (0 <= frame_id < FRAME_COUNT):
    raise LightGardenSphereError(f"frame_id must be integer in [0, {FRAME_COUNT - 1}]")

  centroid = compute_centroid(rows)
  num = tuple(int(v) for v in centroid["numerator"])
  den = int(centroid["denominator"])
  perm, sign = _TRANSFORMS[frame_id]

  transformed: List[List[int]] = []
  for p in rows:
    delta_num = tuple((p[i] * den) - num[i] for i in range(4))
    t = _apply_transform(delta_num, perm, sign)
    transformed.append([int(x) for x in t])

  return {
    "v": SCHEMA_V,
    "authority": "advisory",
    "frame_id": frame_id,
    "point_count": POINT_COUNT,
    "dim": DIM,
    "centroid": {
      "numerator": [int(v) for v in num],
      "denominator": den,
    },
    "transform": {
      "perm": [int(x) for x in perm],
      "sign": [int(x) for x in sign],
    },
    "differences": transformed,
  }


def decode_frame(frame: Dict[str, Any]) -> List[List[int]]:
  validate_frame(frame)
  frame_id = int(frame["frame_id"])
  perm, sign = _TRANSFORMS[frame_id]
  centroid_num = tuple(int(v) for v in frame["centroid"]["numerator"])
  den = int(frame["centroid"]["denominator"])

  out: List[List[int]] = []
  for row in frame["differences"]:
    t = tuple(int(v) for v in row)
    delta_num = _invert_transform(t, perm, sign)
    point_vals: List[int] = []
    for i in range(4):
      num = delta_num[i] + centroid_num[i]
      if num % den != 0:
        raise LightGardenSphereError("non-integral decode detected; frame is invalid")
      point_vals.append(num // den)
    out.append(point_vals)
  return out


def encode_sphere(points: Sequence[Sequence[int]]) -> Dict[str, Any]:
  rows = _validate_points(points)
  frames = [encode_frame(rows, fid) for fid in range(FRAME_COUNT)]
  return {
    "v": "tetragrammatron.light_garden_sphere.bundle.v0",
    "authority": "advisory",
    "frame_count": FRAME_COUNT,
    "point_count": POINT_COUNT,
    "frames": frames,
  }


def validate_frame(frame: Dict[str, Any]) -> None:
  if not isinstance(frame, dict):
    raise LightGardenSphereError("frame must be object")
  _require_exact_keys(frame, ("v", "authority", "frame_id", "point_count", "dim", "centroid", "transform", "differences"), "frame")
  if frame["v"] != SCHEMA_V:
    raise LightGardenSphereError("frame schema mismatch")
  if frame["authority"] != "advisory":
    raise LightGardenSphereError("frame authority must be advisory")
  if not isinstance(frame["frame_id"], int) or not (0 <= frame["frame_id"] < FRAME_COUNT):
    raise LightGardenSphereError("frame_id out of range")
  if frame["point_count"] != POINT_COUNT:
    raise LightGardenSphereError("frame point_count mismatch")
  if frame["dim"] != DIM:
    raise LightGardenSphereError("frame dim mismatch")

  centroid = frame["centroid"]
  if not isinstance(centroid, dict):
    raise LightGardenSphereError("centroid must be object")
  _require_exact_keys(centroid, ("numerator", "denominator"), "centroid")
  if not isinstance(centroid["numerator"], list) or len(centroid["numerator"]) != DIM:
    raise LightGardenSphereError("centroid numerator must be 4-length list")
  if centroid["denominator"] != POINT_COUNT:
    raise LightGardenSphereError("centroid denominator mismatch")

  transform = frame["transform"]
  if not isinstance(transform, dict):
    raise LightGardenSphereError("transform must be object")
  _require_exact_keys(transform, ("perm", "sign"), "transform")
  perm = transform["perm"]
  sign = transform["sign"]
  if sorted(perm) != [0, 1, 2, 3]:
    raise LightGardenSphereError("transform perm invalid")
  if any(s not in (-1, 1) for s in sign):
    raise LightGardenSphereError("transform sign invalid")

  diffs = frame["differences"]
  if not isinstance(diffs, list) or len(diffs) != POINT_COUNT:
    raise LightGardenSphereError("differences must contain 60 rows")
  for row in diffs:
    if not isinstance(row, list) or len(row) != DIM:
      raise LightGardenSphereError("difference row must be length-4 list")
    if any(not isinstance(v, int) for v in row):
      raise LightGardenSphereError("difference values must be integers")

