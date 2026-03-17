#!/usr/bin/env python3
"""Wave27F control-superposition validator (fail-closed, deterministic)."""

from __future__ import annotations

from typing import Any, Dict, List, Sequence

from runtime.tetragrammatron.pure.common import canonical_json


SCHEMA_V = "tetragrammatron.control_superposition.v0"
ROOT_BLOCK = [0x3C, 0x3D, 0x3E, 0x3F, 0x40]
LANGUAGE_BOUNDARY = [0x41, 0xFF]
PUBLIC_SPACE = [0xB3, 0x3C, 0x3D, 0x3E, 0x00]
INNER_SPACE = [0xB3, 0x3C, 0x3D, 0xFF, 0x3E, 0x3F, 0xFF, 0x40, 0x41, 0x00]
PRIVATE_SPACE = [0xFF, 0xB3, 0x3E, 0x3C, 0x00, 0x41]


class ControlSuperpositionError(ValueError):
  pass


def _require_exact_keys(obj: Dict[str, Any], allowed: Sequence[str], label: str) -> None:
  got = set(obj.keys())
  expect = set(allowed)
  if got != expect:
    raise ControlSuperpositionError(f"{label} keyset mismatch: expected={sorted(expect)} got={sorted(got)}")


def _validate_byte_seq(value: Any, label: str) -> List[int]:
  if not isinstance(value, list) or not value:
    raise ControlSuperpositionError(f"{label} must be non-empty list")
  out: List[int] = []
  for v in value:
    if not isinstance(v, int) or v < 0 or v > 255:
      raise ControlSuperpositionError(f"{label} must contain byte integers")
    out.append(v)
  return out


def validate_control_superposition(payload: Dict[str, Any]) -> None:
  if not isinstance(payload, dict):
    raise ControlSuperpositionError("payload must be object")

  _require_exact_keys(
    payload,
    (
      "v",
      "authority",
      "upper_bound_sphere",
      "root_block",
      "language_boundary",
      "public_space",
      "inner_point_space",
      "private_space",
      "klein_points",
      "tetrahedral_layers",
      "centroid_ref",
    ),
    "payload",
  )

  if payload["v"] != SCHEMA_V:
    raise ControlSuperpositionError("schema mismatch")
  if payload["authority"] != "advisory":
    raise ControlSuperpositionError("authority must be advisory")

  ub = payload["upper_bound_sphere"]
  if not isinstance(ub, dict):
    raise ControlSuperpositionError("upper_bound_sphere must be object")
  _require_exact_keys(ub, ("start", "end"), "upper_bound_sphere")
  if ub["start"] != 0x00 or ub["end"] != 0xB3:
    raise ControlSuperpositionError("upper_bound_sphere must be {start:0x00,end:0xB3}")

  if _validate_byte_seq(payload["root_block"], "root_block") != ROOT_BLOCK:
    raise ControlSuperpositionError("root_block mismatch")
  if _validate_byte_seq(payload["language_boundary"], "language_boundary") != LANGUAGE_BOUNDARY:
    raise ControlSuperpositionError("language_boundary mismatch")
  if _validate_byte_seq(payload["public_space"], "public_space") != PUBLIC_SPACE:
    raise ControlSuperpositionError("public_space mismatch")
  if _validate_byte_seq(payload["inner_point_space"], "inner_point_space") != INNER_SPACE:
    raise ControlSuperpositionError("inner_point_space mismatch")
  if _validate_byte_seq(payload["private_space"], "private_space") != PRIVATE_SPACE:
    raise ControlSuperpositionError("private_space mismatch")

  points = _validate_byte_seq(payload["klein_points"], "klein_points")
  if points != list(range(0x00, 0x3C)):
    raise ControlSuperpositionError("klein_points must be canonical 0x00..0x3B")

  layers = payload["tetrahedral_layers"]
  if not isinstance(layers, list) or len(layers) != 3:
    raise ControlSuperpositionError("tetrahedral_layers must be list of 3 entries")
  for i, layer in enumerate(layers):
    if not isinstance(layer, dict):
      raise ControlSuperpositionError(f"tetrahedral_layers[{i}] must be object")
    _require_exact_keys(layer, ("name", "codes"), f"tetrahedral_layers[{i}]")
    if not isinstance(layer["name"], str) or not layer["name"]:
      raise ControlSuperpositionError(f"tetrahedral_layers[{i}].name must be non-empty string")
    codes = layer["codes"]
    if not isinstance(codes, list) or len(codes) != 4 or any(not isinstance(c, str) or not c for c in codes):
      raise ControlSuperpositionError(f"tetrahedral_layers[{i}].codes must be 4 non-empty strings")

  c = payload["centroid_ref"]
  if not isinstance(c, list) or len(c) != 3 or any(not isinstance(v, int) for v in c):
    raise ControlSuperpositionError("centroid_ref must be [int,int,int]")
  if c != [3, 3, 3]:
    raise ControlSuperpositionError("centroid_ref must be [3,3,3]")


def canonical_control_superposition(payload: Dict[str, Any]) -> str:
  validate_control_superposition(payload)
  return canonical_json(payload)
