#!/usr/bin/env python3
"""RS (0x1E): record-level pure operations."""

from __future__ import annotations

from typing import Any, Dict, List

from .common import clone, deterministic_id, require_dict, require_non_empty_string


def record_create(data: Dict[str, Any]) -> Dict[str, Any]:
  payload = clone(require_dict(data, "data"))
  record_id = deterministic_id("record", payload)
  return {
    "id": record_id,
    "data": payload,
  }


def record_update(record: Dict[str, Any], delta: Dict[str, Any]) -> Dict[str, Any]:
  base = clone(require_dict(record, "record"))
  patch = clone(require_dict(delta, "delta"))
  merged = clone(base.get("data", {}))
  merged.update(patch)
  base["data"] = merged
  return base


def record_delete(records: List[Dict[str, Any]], record_id: str) -> List[Dict[str, Any]]:
  target = require_non_empty_string(record_id, "record_id")
  source = [clone(require_dict(r, "record")) for r in records]
  kept = [r for r in source if r.get("id") != target]
  if len(kept) == len(source):
    raise ValueError("record id not found")
  return kept
