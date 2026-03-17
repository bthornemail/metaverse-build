#!/usr/bin/env python3
"""US (0x1F): unit-level pure operations."""

from __future__ import annotations

from typing import Any, Dict

from .common import clone, require_dict, require_non_empty_string


def unit_get(record: Dict[str, Any], field: str) -> Any:
  source = require_dict(record, "record")
  key = require_non_empty_string(field, "field")
  return clone(source.get("data", {}).get(key))


def unit_set(record: Dict[str, Any], field: str, value: Any) -> Dict[str, Any]:
  source = clone(require_dict(record, "record"))
  key = require_non_empty_string(field, "field")
  payload = clone(source.get("data", {}))
  payload[key] = clone(value)
  source["data"] = payload
  return source


def unit_validate(value: Any, expected_type: str) -> bool:
  kind = require_non_empty_string(expected_type, "expected_type")
  table = {
    "string": str,
    "number": (int, float),
    "boolean": bool,
    "object": dict,
    "array": list,
    "null": type(None),
  }
  if kind not in table:
    raise ValueError("unsupported expected_type")
  return isinstance(value, table[kind])
