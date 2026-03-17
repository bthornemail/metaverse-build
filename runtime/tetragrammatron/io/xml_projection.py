#!/usr/bin/env python3
"""XML projection surface for tetragrammatron control-code world dialect."""

from __future__ import annotations

import json
import xml.etree.ElementTree as ET
from typing import Any, Dict, List

from .seed_companion import companion_to_xml, to_projection_metadata, validate_companion

FS = "0x1C"
GS = "0x1D"
RS = "0x1E"
US = "0x1F"


def _fail(msg: str) -> None:
  raise ValueError(msg)


def _require_exact_attrs(node: ET.Element, allowed: set[str], label: str) -> None:
  got = set(node.attrib.keys())
  if got != allowed:
    _fail(f"{label} attributes mismatch: expected={sorted(allowed)} got={sorted(got)}")


def _to_type_name(value: Any) -> str:
  if value is None:
    return "null"
  if isinstance(value, bool):
    return "boolean"
  if isinstance(value, (int, float)):
    return "number"
  if isinstance(value, str):
    return "string"
  if isinstance(value, list):
    return "array"
  if isinstance(value, dict):
    return "object"
  _fail(f"unsupported unit value type: {type(value).__name__}")


def _type_matches(value: Any, type_name: str) -> bool:
  table = {
    "null": type(None),
    "boolean": bool,
    "number": (int, float),
    "string": str,
    "array": list,
    "object": dict,
  }
  if type_name not in table:
    _fail(f"unsupported unit type: {type_name}")
  return isinstance(value, table[type_name])


def world_to_xml(world: Dict[str, Any]) -> str:
  if not isinstance(world, dict):
    _fail("world must be object")
  if world.get("schema") != "tetragrammatron.world.v1":
    _fail("world schema mismatch")

  root = ET.Element("control", {"code": FS})
  world_el = ET.SubElement(root, "world", {
    "id": str(world.get("id", "")),
    "name": str(world.get("name", "")),
    "authority": str(world.get("authority", "advisory")),
    "schema": str(world.get("schema")),
  })

  groups_ctl = ET.SubElement(world_el, "control", {"code": GS})
  groups = list(world.get("groups", []))
  groups = sorted(groups, key=lambda g: (str(g.get("id", "")), str(g.get("name", ""))))

  for group in groups:
    group_el = ET.SubElement(groups_ctl, "group", {
      "id": str(group.get("id", "")),
      "name": str(group.get("name", "")),
    })
    records_ctl = ET.SubElement(group_el, "control", {"code": RS})
    records = list(group.get("records", []))
    records = sorted(records, key=lambda r: str(r.get("id", "")))

    for record in records:
      record_el = ET.SubElement(records_ctl, "record", {"id": str(record.get("id", ""))})
      units_ctl = ET.SubElement(record_el, "control", {"code": US})
      data = record.get("data", {})
      if not isinstance(data, dict):
        _fail("record.data must be object")
      for key in sorted(data.keys()):
        value = data[key]
        unit_el = ET.SubElement(units_ctl, "unit", {
          "key": str(key),
          "type": _to_type_name(value),
        })
        unit_el.text = json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False)

  return ET.tostring(root, encoding="unicode", method="xml", short_empty_elements=False)


def xml_to_world(xml_text: str) -> Dict[str, Any]:
  if not isinstance(xml_text, str) or not xml_text.strip():
    _fail("xml_text must be non-empty string")

  root = ET.fromstring(xml_text)
  if root.tag != "control":
    _fail("root must be <control>")
  _require_exact_attrs(root, {"code"}, "root control")
  if root.attrib["code"] != FS:
    _fail("root control code mismatch")

  root_children = list(root)
  if len(root_children) != 1 or root_children[0].tag != "world":
    _fail("root must contain exactly one <world>")

  world_el = root_children[0]
  _require_exact_attrs(world_el, {"id", "name", "authority", "schema"}, "world")

  groups_ctl_children = list(world_el)
  if len(groups_ctl_children) != 1 or groups_ctl_children[0].tag != "control":
    _fail("world must contain exactly one group control")

  groups_ctl = groups_ctl_children[0]
  _require_exact_attrs(groups_ctl, {"code"}, "groups control")
  if groups_ctl.attrib["code"] != GS:
    _fail("groups control code mismatch")

  groups: List[Dict[str, Any]] = []
  for group_el in list(groups_ctl):
    if group_el.tag != "group":
      _fail("groups control may only contain <group>")
    _require_exact_attrs(group_el, {"id", "name"}, "group")

    record_ctl_children = list(group_el)
    if len(record_ctl_children) != 1 or record_ctl_children[0].tag != "control":
      _fail("group must contain exactly one record control")

    records_ctl = record_ctl_children[0]
    _require_exact_attrs(records_ctl, {"code"}, "records control")
    if records_ctl.attrib["code"] != RS:
      _fail("records control code mismatch")

    records: List[Dict[str, Any]] = []
    for record_el in list(records_ctl):
      if record_el.tag != "record":
        _fail("records control may only contain <record>")
      _require_exact_attrs(record_el, {"id"}, "record")

      units_ctl_children = list(record_el)
      if len(units_ctl_children) != 1 or units_ctl_children[0].tag != "control":
        _fail("record must contain exactly one unit control")

      units_ctl = units_ctl_children[0]
      _require_exact_attrs(units_ctl, {"code"}, "units control")
      if units_ctl.attrib["code"] != US:
        _fail("units control code mismatch")

      data: Dict[str, Any] = {}
      for unit_el in list(units_ctl):
        if unit_el.tag != "unit":
          _fail("units control may only contain <unit>")
        _require_exact_attrs(unit_el, {"key", "type"}, "unit")
        key = unit_el.attrib["key"]
        if key in data:
          _fail(f"duplicate unit key: {key}")

        value = json.loads(unit_el.text or "null")
        type_name = unit_el.attrib["type"]
        if not _type_matches(value, type_name):
          _fail(f"unit type mismatch for key={key}")
        data[key] = value

      records.append({"id": record_el.attrib["id"], "data": data})

    groups.append({"id": group_el.attrib["id"], "name": group_el.attrib["name"], "records": records})

  return {
    "id": world_el.attrib["id"],
    "name": world_el.attrib["name"],
    "authority": world_el.attrib["authority"],
    "schema": world_el.attrib["schema"],
    "groups": groups,
  }


def projection_metadata(world_xml: str, companion: Dict[str, Any] | None = None) -> Dict[str, Any]:
  """Return advisory projection metadata for world XML and optional seed companion."""
  if not isinstance(world_xml, str) or not world_xml.strip():
    _fail("world_xml must be non-empty string")
  metadata: Dict[str, Any] = {
    "authority": "advisory",
    "projection": "xml",
    "xml_bytes": len(world_xml.encode("utf-8")),
  }
  if companion is not None:
    validate_companion(companion)
    metadata["seed_companion"] = to_projection_metadata(companion)
  return metadata


def companion_xml_block(companion: Dict[str, Any]) -> str:
  """Emit optional XML namespace block for projection consumers."""
  validate_companion(companion)
  return companion_to_xml(companion)
