#!/usr/bin/env python3
"""Self-instantiating XML helper (strict, deterministic, fail-closed)."""

from __future__ import annotations

import xml.etree.ElementTree as ET
from typing import Dict, List


FS = "0x1C"
GS = "0x1D"
RS = "0x1E"
US = "0x1F"


class LivingXmlError(ValueError):
  pass


def _fail(message: str) -> None:
  raise LivingXmlError(message)


def _require_exact_attrs(el: ET.Element, required: set[str], label: str) -> None:
  keys = set(el.attrib.keys())
  if keys != required:
    _fail(f"{label} attrs mismatch: expected {sorted(required)}, got {sorted(keys)}")


def _require_whitespace_only(value: str | None, label: str) -> None:
  if value is not None and value.strip() != "":
    _fail(f"{label} must be whitespace-only")


def next_fano_tick(tick: int) -> int:
  if tick < 1 or tick > 7:
    _fail("tick must be in 1..7")
  return (tick % 7) + 1


def circulation_role(tick: int) -> str:
  if tick < 1 or tick > 7:
    _fail("tick must be in 1..7")
  # 7-beat closed circulation cycle.
  phases = {
    1: "heart.fs",
    2: "arteries.gs",
    3: "veins.rs",
    4: "capillaries.us",
    5: "veins.rs",
    6: "arteries.gs",
    7: "heart.fs",
  }
  return phases[tick]


def parse_living_xml(xml_text: str) -> Dict[str, object]:
  try:
    root = ET.fromstring(xml_text)
  except ET.ParseError as exc:
    _fail(f"invalid xml: {exc}")
    raise

  if root.tag != "fs":
    _fail("root must be <fs>")
  root_keys = set(root.attrib.keys())
  if root_keys not in ({"code"}, {"code", "tick"}):
    _fail(f"fs attrs mismatch: expected ['code'] or ['code', 'tick'], got {sorted(root_keys)}")
  if root.attrib["code"] != FS:
    _fail("fs code mismatch")
  tick_raw = root.attrib.get("tick", "1")
  try:
    tick = int(tick_raw)
  except ValueError:
    _fail("tick must be integer")
    raise
  if tick < 1 or tick > 7:
    _fail("tick must be in 1..7")
  _require_whitespace_only(root.text, "fs text")

  gs_nodes = list(root)
  units: List[str] = []
  gs_view: List[Dict[str, object]] = []
  if not gs_nodes:
    _fail("fs must contain at least one <gs>")
  for gs_node in gs_nodes:
    if gs_node.tag != "gs":
      _fail("fs may only contain <gs>")
    _require_whitespace_only(gs_node.tail, "gs tail")
    _require_exact_attrs(gs_node, {"code"}, "gs")
    if gs_node.attrib["code"] != GS:
      _fail("gs code mismatch")
    _require_whitespace_only(gs_node.text, "gs text")

    rs_nodes = list(gs_node)
    if not rs_nodes:
      _fail("gs must contain at least one <rs>")
    rs_view: List[Dict[str, object]] = []
    for rs_node in rs_nodes:
      if rs_node.tag != "rs":
        _fail("gs may only contain <rs>")
      _require_whitespace_only(rs_node.tail, "rs tail")
      _require_exact_attrs(rs_node, {"code"}, "rs")
      if rs_node.attrib["code"] != RS:
        _fail("rs code mismatch")
      _require_whitespace_only(rs_node.text, "rs text")

      us_nodes = list(rs_node)
      if not us_nodes:
        _fail("rs must contain at least one <us>")
      us_view: List[Dict[str, object]] = []
      for child in us_nodes:
        if child.tag != "us":
          _fail("rs may only contain <us>")
        _require_exact_attrs(child, {"code"}, "us")
        if child.attrib["code"] != US:
          _fail("us code mismatch")
        if list(child):
          _fail("us must not contain nested elements")
        _require_whitespace_only(child.tail, "us tail")
        value = child.text or ""
        units.append(value)
        us_view.append({"us": {"code": US, "content": value}})
      rs_view.append({"rs": {"code": RS, "children": us_view}})
    gs_view.append({"gs": {"code": GS, "children": rs_view}})

  return {
    "v": "tetragrammatron.living_xml.v0",
    "authority": "advisory",
    "tick": tick,
    "role": circulation_role(tick),
    "units": units,
    "fs": {"code": FS, "tick": tick, "children": gs_view},
  }


def advance_living_xml(xml_text: str) -> str:
  parse_living_xml(xml_text)
  root = ET.fromstring(xml_text)
  current_tick = int(root.attrib.get("tick", "1"))
  root.attrib["tick"] = str(next_fano_tick(current_tick))
  return ET.tostring(root, encoding="unicode", short_empty_elements=False)


def circulation_trace(xml_text: str, steps: int) -> List[int]:
  if steps < 0:
    _fail("steps must be >= 0")
  out: List[int] = []
  current = xml_text
  for _ in range(steps):
    parsed = parse_living_xml(current)
    out.append(int(parsed["tick"]))
    current = advance_living_xml(current)
  return out
