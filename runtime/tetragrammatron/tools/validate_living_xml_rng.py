#!/usr/bin/env python3
"""Deterministic schema validator for Wave27H living XML Relax NG contract."""

from __future__ import annotations

import argparse
import xml.etree.ElementTree as ET


RNG_NS = "{http://relaxng.org/ns/structure/1.0}"


class SchemaValidationError(ValueError):
  pass


def _fail(msg: str) -> None:
  raise SchemaValidationError(msg)


def _require_ws(value: str | None, label: str) -> None:
  if value is not None and value.strip() != "":
    _fail(f"{label} must be whitespace-only")


def _extract_code(schema_root: ET.Element, element_name: str) -> str:
  for element in schema_root.iter(f"{RNG_NS}element"):
    if element.attrib.get("name") != element_name:
      continue
    for attr in element.findall(f"{RNG_NS}attribute"):
      if attr.attrib.get("name") == "code":
        value = attr.find(f"{RNG_NS}value")
        if value is None or value.text is None:
          _fail(f"schema missing code value for {element_name}")
        return value.text
  _fail(f"schema missing element {element_name}")
  raise AssertionError("unreachable")


def _extract_tick_bounds(schema_root: ET.Element) -> tuple[int, int]:
  for element in schema_root.iter(f"{RNG_NS}element"):
    if element.attrib.get("name") != "fs":
      continue
    optional = element.find(f"{RNG_NS}optional")
    if optional is None:
      break
    attr = optional.find(f"{RNG_NS}attribute")
    if attr is None or attr.attrib.get("name") != "tick":
      break
    data = attr.find(f"{RNG_NS}data")
    if data is None or data.attrib.get("type") != "integer":
      break
    min_value = None
    max_value = None
    for param in data.findall(f"{RNG_NS}param"):
      name = param.attrib.get("name")
      if name == "minInclusive":
        min_value = int(param.text or "0")
      if name == "maxInclusive":
        max_value = int(param.text or "0")
    if min_value is not None and max_value is not None:
      return (min_value, max_value)
  _fail("schema missing tick bounds")
  raise AssertionError("unreachable")


def validate(schema_path: str, xml_path: str) -> None:
  try:
    schema_root = ET.parse(schema_path).getroot()
  except ET.ParseError as exc:
    _fail(f"invalid schema xml: {exc}")
    raise
  codes = {
    "fs": _extract_code(schema_root, "fs"),
    "gs": _extract_code(schema_root, "gs"),
    "rs": _extract_code(schema_root, "rs"),
    "us": _extract_code(schema_root, "us"),
  }
  tick_min, tick_max = _extract_tick_bounds(schema_root)

  try:
    root = ET.parse(xml_path).getroot()
  except ET.ParseError as exc:
    _fail(f"invalid xml: {exc}")
    raise
  if root.tag != "fs":
    _fail("root must be fs")
  attrs = set(root.attrib.keys())
  if attrs not in ({"code"}, {"code", "tick"}):
    _fail("fs attrs mismatch")
  if root.attrib.get("code") != codes["fs"]:
    _fail("fs code mismatch")
  tick_raw = root.attrib.get("tick", str(tick_min))
  try:
    tick = int(tick_raw)
  except ValueError:
    _fail("tick must be integer")
    raise
  if tick < tick_min or tick > tick_max:
    _fail("tick out of schema bounds")
  _require_ws(root.text, "fs text")

  gs_nodes = list(root)
  if not gs_nodes:
    _fail("fs must contain gs")
  for gs in gs_nodes:
    if gs.tag != "gs":
      _fail("fs may only contain gs")
    _require_ws(gs.tail, "gs tail")
    if gs.attrib != {"code": codes["gs"]}:
      _fail("gs code mismatch")
    _require_ws(gs.text, "gs text")
    rs_nodes = list(gs)
    if not rs_nodes:
      _fail("gs must contain rs")
    for rs in rs_nodes:
      if rs.tag != "rs":
        _fail("gs may only contain rs")
      _require_ws(rs.tail, "rs tail")
      if rs.attrib != {"code": codes["rs"]}:
        _fail("rs code mismatch")
      _require_ws(rs.text, "rs text")
      us_nodes = list(rs)
      if not us_nodes:
        _fail("rs must contain us")
      for us in us_nodes:
        if us.tag != "us":
          _fail("rs may only contain us")
        if us.attrib != {"code": codes["us"]}:
          _fail("us code mismatch")
        if list(us):
          _fail("us must be terminal")
        _require_ws(us.tail, "us tail")


def main() -> int:
  parser = argparse.ArgumentParser()
  parser.add_argument("schema")
  parser.add_argument("xml")
  args = parser.parse_args()
  try:
    validate(args.schema, args.xml)
  except SchemaValidationError as exc:
    print(f"schema validation failed: {exc}")
    return 1
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
