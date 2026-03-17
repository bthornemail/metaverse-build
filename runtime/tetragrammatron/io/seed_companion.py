#!/usr/bin/env python3
"""Wave27J seed companion JSON/XML projection helpers."""

from __future__ import annotations

import xml.etree.ElementTree as ET
import re
from typing import Any, Dict

from runtime.tetragrammatron.identity import compute_oid, compute_typed_sid, validate_clock
from runtime.tetragrammatron.io.seed_algebra import closure_fixpoint, normalize_seed, phase_from_header


COMPANION_V = "wave27J.seed_companion.v0"
COMPANION_NS = "urn:tetragrammatron:seed-companion:v1"
_SHA256_RE = re.compile(r"^sha256:[0-9a-f]{64}$")


class SeedCompanionError(ValueError):
  pass


def _fail(message: str) -> None:
  raise SeedCompanionError(message)


def _is_sha256(value: Any) -> bool:
  return isinstance(value, str) and bool(_SHA256_RE.match(value))


def _validate_links(links: Any) -> None:
  if not isinstance(links, dict) or set(links.keys()) != {"derived_from", "references"}:
    _fail("links keyset mismatch")
  for key in ("derived_from", "references"):
    values = links[key]
    if not isinstance(values, list):
      _fail(f"links.{key} must be list")
    for item in values:
      if not _is_sha256(item):
        _fail(f"links.{key} item must be sha256")


def build_companion(
  seed: int,
  obj_type: str,
  clock: Dict[str, int],
  prev_oid: str | None,
  next_oid: str | None = None,
  links: Dict[str, Any] | None = None,
) -> Dict[str, Any]:
  s = normalize_seed(seed)
  header = closure_fixpoint(s)
  phase = phase_from_header(header)
  canonical_header = f"{header:07b}"
  sid = compute_typed_sid(obj_type, canonical_header)
  oid = compute_oid(clock, sid, prev_oid)
  if links is None:
    links = {"derived_from": [], "references": []}
  companion = {
    "v": COMPANION_V,
    "authority": "advisory",
    "seed": s,
    "header": header,
    "phase": phase,
    "type": obj_type,
    "sid": sid,
    "clock": dict(clock),
    "oid": oid,
    "prev_oid": prev_oid,
    "next_oid": next_oid,
    "links": links,
  }
  validate_companion(companion)
  return companion


def companion_reference(companion: Dict[str, Any]) -> Dict[str, str]:
  """Return minimal advisory reference hook for projection metadata."""
  validate_companion(companion)
  return {"sid": companion["sid"], "oid": companion["oid"], "type": companion["type"]}


def validate_companion(companion: Dict[str, Any]) -> None:
  required = {
    "v", "authority", "seed", "header", "phase", "type", "sid",
    "clock", "oid", "prev_oid", "next_oid", "links",
  }
  if set(companion.keys()) != required:
    _fail("companion keyset mismatch")
  if companion["v"] != COMPANION_V:
    _fail("companion version mismatch")
  if companion["authority"] != "advisory":
    _fail("companion authority mismatch")

  seed = normalize_seed(companion["seed"])
  header = normalize_seed(companion["header"])
  expected_header = closure_fixpoint(seed)
  if header != expected_header:
    _fail("companion header mismatch")
  expected_phase = phase_from_header(header)
  if companion["phase"] != expected_phase:
    _fail("companion phase mismatch")

  canonical_header = f"{header:07b}"
  expected_sid = compute_typed_sid(companion["type"], canonical_header)
  if companion["sid"] != expected_sid:
    _fail("companion sid mismatch")

  validate_clock(companion["clock"])
  expected_oid = compute_oid(companion["clock"], companion["sid"], companion["prev_oid"])
  if companion["oid"] != expected_oid:
    _fail("companion oid mismatch")

  for key in ("prev_oid", "next_oid"):
    value = companion[key]
    if value is not None and not _is_sha256(value):
      _fail(f"{key} must be sha256 or null")

  _validate_links(companion["links"])


def derive_seed_from_wave27h_report(report: Dict[str, Any]) -> int:
  if not isinstance(report, dict) or report.get("v") != "phase27H.living_xml.v0":
    _fail("wave27H report version mismatch")
  cases = report.get("cases")
  if not isinstance(cases, list) or len(cases) < 1:
    _fail("wave27H report cases missing")
  first = cases[0]
  parsed = first.get("parsed") if isinstance(first, dict) else None
  code = parsed.get("code") if isinstance(parsed, dict) else None
  if not isinstance(code, str) or not code.startswith("0x"):
    _fail("wave27H parsed code missing")
  return int(code, 16) & 0x7F


def validate_companion_wave27h_continuity(report: Dict[str, Any], companion: Dict[str, Any]) -> None:
  validate_companion(companion)
  expected_seed = derive_seed_from_wave27h_report(report)
  if companion["seed"] != expected_seed:
    _fail("cross-wave seed continuity mismatch")


def to_projection_metadata(companion: Dict[str, Any]) -> Dict[str, Any]:
  """Advisory-only metadata hook consumed by projection surfaces."""
  validate_companion(companion)
  return {
    "v": COMPANION_V,
    "authority": "advisory",
    "companion_ref": companion_reference(companion),
  }


def companion_to_xml(companion: Dict[str, Any]) -> str:
  validate_companion(companion)

  root = ET.Element(
    f"{{{COMPANION_NS}}}companion",
    {
      "v": companion["v"],
      "authority": companion["authority"],
      "seed": str(companion["seed"]),
      "header": str(companion["header"]),
      "phase": str(companion["phase"]),
      "type": companion["type"],
      "sid": companion["sid"],
      "oid": companion["oid"],
      "prev_oid": companion["prev_oid"] or "",
      "next_oid": companion["next_oid"] or "",
    },
  )

  ET.SubElement(
    root,
    f"{{{COMPANION_NS}}}clock",
    {
      "frame": str(companion["clock"]["frame"]),
      "tick": str(companion["clock"]["tick"]),
      "control": str(companion["clock"]["control"]),
    },
  )

  links_el = ET.SubElement(root, f"{{{COMPANION_NS}}}links")
  for rel in ("derived_from", "references"):
    rel_el = ET.SubElement(links_el, f"{{{COMPANION_NS}}}{rel}")
    for value in companion["links"][rel]:
      item = ET.SubElement(rel_el, f"{{{COMPANION_NS}}}sid")
      item.text = value

  return ET.tostring(root, encoding="unicode", short_empty_elements=False)


def companion_from_xml(xml_text: str) -> Dict[str, Any]:
  try:
    root = ET.fromstring(xml_text)
  except ET.ParseError as exc:
    _fail(f"invalid companion xml: {exc}")

  if root.tag != f"{{{COMPANION_NS}}}companion":
    _fail("companion root mismatch")

  attrs = root.attrib
  expected_attrs = {"v", "authority", "seed", "header", "phase", "type", "sid", "oid", "prev_oid", "next_oid"}
  if set(attrs.keys()) != expected_attrs:
    _fail("companion xml attrs mismatch")

  children = list(root)
  if len(children) != 2 or children[0].tag != f"{{{COMPANION_NS}}}clock" or children[1].tag != f"{{{COMPANION_NS}}}links":
    _fail("companion xml child structure mismatch")

  clock_el = children[0]
  if set(clock_el.attrib.keys()) != {"frame", "tick", "control"}:
    _fail("companion xml clock attrs mismatch")

  links_el = children[1]
  rel_nodes = list(links_el)
  rel_by_tag = {node.tag: node for node in rel_nodes}
  expected_rel = {f"{{{COMPANION_NS}}}derived_from", f"{{{COMPANION_NS}}}references"}
  if set(rel_by_tag.keys()) != expected_rel:
    _fail("companion xml links structure mismatch")

  def _read_rel(tag: str) -> list[str]:
    values = []
    for child in rel_by_tag[tag]:
      if child.tag != f"{{{COMPANION_NS}}}sid":
        _fail("companion xml links item mismatch")
      values.append(child.text or "")
    return values

  companion = {
    "v": attrs["v"],
    "authority": attrs["authority"],
    "seed": int(attrs["seed"]),
    "header": int(attrs["header"]),
    "phase": int(attrs["phase"]),
    "type": attrs["type"],
    "sid": attrs["sid"],
    "clock": {
      "frame": int(clock_el.attrib["frame"]),
      "tick": int(clock_el.attrib["tick"]),
      "control": int(clock_el.attrib["control"]),
    },
    "oid": attrs["oid"],
    "prev_oid": attrs["prev_oid"] or None,
    "next_oid": attrs["next_oid"] or None,
    "links": {
      "derived_from": _read_rel(f"{{{COMPANION_NS}}}derived_from"),
      "references": _read_rel(f"{{{COMPANION_NS}}}references"),
    },
  }
  validate_companion(companion)
  return companion
