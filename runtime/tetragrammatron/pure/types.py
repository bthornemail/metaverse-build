#!/usr/bin/env python3
"""Advisory resolution layer: epistemic + geometric data types."""

from __future__ import annotations

from dataclasses import dataclass
from math import sqrt
from typing import Any, Dict, Iterable, List

from .common import clone, require_dict


UNIVERSAL_CONSTANTS = {
  "c": 299792458.0,
  "hbar": 1.054571817e-34,
  "G": 6.67430e-11,
  "phi": (1.0 + sqrt(5.0)) / 2.0,
  "pi": 3.141592653589793,
  "e": 2.718281828459045,
  "alpha": 0.0072973525693,
}

_SOLID_NAMES = (
  "tetrahedron",
  "cube",
  "octahedron",
  "dodecahedron",
  "icosahedron",
  "rhombic_dodecahedron",
  "truncated_icosahedron",
)


@dataclass(frozen=True)
class EpistemicVector:
  kk: float
  ku: float
  uk: float
  uu: float

  @classmethod
  def from_world(cls, world: Dict[str, Any]) -> "EpistemicVector":
    source = require_dict(world, "world")
    return cls(
      kk=float(source.get("kk", 1.0)),
      ku=float(source.get("ku", 0.0)),
      uk=float(source.get("uk", 0.0)),
      uu=float(source.get("uu", 0.0)),
    )

  def to_dict(self) -> Dict[str, float]:
    return {
      "KK": self.kk,
      "KU": self.ku,
      "UK": self.uk,
      "UU": self.uu,
    }


@dataclass(frozen=True)
class E8Point:
  coords: tuple[float, float, float, float, float, float, float, float]

  @classmethod
  def from_epistemic(cls, ev: EpistemicVector) -> "E8Point":
    # Deterministic 8D embedding derived from the 4 epistemic components.
    coords = (
      ev.kk,
      ev.ku,
      ev.uk,
      ev.uu,
      ev.kk - ev.uu,
      ev.ku + ev.uk,
      ev.kk + ev.ku - ev.uk,
      ev.kk + ev.ku + ev.uk + ev.uu,
    )
    return cls(coords=coords)


@dataclass(frozen=True)
class Octonion:
  components: tuple[float, float, float, float, float, float, float, float]

  @classmethod
  def from_e8_point(cls, point: E8Point) -> "Octonion":
    return cls(components=point.coords)


def _solid_from_point(point: E8Point) -> str:
  selector = int(abs(sum(point.coords)) * 1000) % len(_SOLID_NAMES)
  return _SOLID_NAMES[selector]


def _certainty(ev: EpistemicVector) -> float:
  raw = 1.0 - ev.uu
  if raw < 0.0:
    return 0.0
  if raw > 1.0:
    return 1.0
  return raw


def resolve_world(world: Dict[str, Any]) -> Dict[str, Any]:
  source = clone(require_dict(world, "world"))
  epistemic = EpistemicVector.from_world(source)
  point = E8Point.from_epistemic(epistemic)
  octonion = Octonion.from_e8_point(point)

  return {
    "world": source,
    "epistemic": epistemic.to_dict(),
    "e8_point": list(point.coords),
    "octonion": list(octonion.components),
    "solid": _solid_from_point(point),
    "constants": clone(UNIVERSAL_CONSTANTS),
    "certainty": _certainty(epistemic),
    "authority": "advisory",
  }


def resolve_if_world(value: Any) -> Any:
  if not isinstance(value, dict):
    return value
  if value.get("schema") != "tetragrammatron.world.v1":
    return value
  return resolve_world(value)


def solid_catalog() -> List[str]:
  return list(_SOLID_NAMES)


def constants_keys() -> Iterable[str]:
  return UNIVERSAL_CONSTANTS.keys()
