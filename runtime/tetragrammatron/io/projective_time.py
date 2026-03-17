#!/usr/bin/env python3
"""Advisory projective-time signatures for XML projection surfaces."""

from __future__ import annotations

from dataclasses import dataclass
from math import sqrt
import xml.etree.ElementTree as ET


@dataclass(frozen=True)
class TimeSignature:
  element_count: int
  control_count: int
  unit_count: int
  payload_char_count: int
  a: int
  b: int
  c: int
  discriminant: int
  class_name: str
  step_length: float
  genus: int


class ProjectiveTimeError(ValueError):
  pass


def _classify(discriminant: int) -> str:
  if discriminant > 0:
    return "hyperbolic"
  if discriminant == 0:
    return "parabolic"
  return "elliptic"


def _iter_elements(root: ET.Element):
  yield root
  for child in list(root):
    yield from _iter_elements(child)


def xml_time_signature(xml_text: str) -> TimeSignature:
  if not isinstance(xml_text, str) or not xml_text.strip():
    raise ProjectiveTimeError("xml_text must be non-empty string")

  root = ET.fromstring(xml_text)
  elements = list(_iter_elements(root))
  element_count = len(elements)
  control_count = sum(1 for e in elements if e.tag == "control")
  unit_count = sum(1 for e in elements if e.tag == "unit")
  payload_char_count = sum(len((e.text or "")) for e in elements if e.tag == "unit")

  # Deterministic quadratic-form coefficients from structure.
  a = max(1, control_count)
  b = unit_count
  c = max(1, element_count - control_count)

  discriminant = b * b - 4 * a * c
  step_length = sqrt(abs(discriminant)) / (2 * a)
  class_name = _classify(discriminant)
  genus = abs(discriminant) % 8

  return TimeSignature(
    element_count=element_count,
    control_count=control_count,
    unit_count=unit_count,
    payload_char_count=payload_char_count,
    a=a,
    b=b,
    c=c,
    discriminant=discriminant,
    class_name=class_name,
    step_length=step_length,
    genus=genus,
  )


def can_sync(left: TimeSignature, right: TimeSignature, *, tol: float = 1e-9) -> bool:
  if left.genus != right.genus:
    return False
  return abs(left.step_length - right.step_length) <= tol
