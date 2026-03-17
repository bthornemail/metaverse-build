#!/usr/bin/env python3
"""GS (0x1D): group-level pure operations."""

from __future__ import annotations

from typing import Any, Dict, List

from .common import clone, deterministic_id, require_dict, require_non_empty_string


def group_create(name: str, metadata: Dict[str, Any] | None = None) -> Dict[str, Any]:
  group_name = require_non_empty_string(name, "name")
  group_meta = require_dict(metadata or {}, "metadata")
  group_id = deterministic_id("group", {"name": group_name, "metadata": group_meta})
  return {
    "id": group_id,
    "name": group_name,
    "metadata": clone(group_meta),
    "records": [],
  }


def group_add(world: Dict[str, Any], group: Dict[str, Any]) -> Dict[str, Any]:
  next_world = clone(require_dict(world, "world"))
  candidate = clone(require_dict(group, "group"))
  existing = {item.get("id") for item in next_world.get("groups", [])}
  if candidate.get("id") in existing:
    raise ValueError("group id already exists")
  next_world.setdefault("groups", []).append(candidate)
  return next_world


def group_remove(world: Dict[str, Any], group_id: str) -> Dict[str, Any]:
  target = require_non_empty_string(group_id, "group_id")
  next_world = clone(require_dict(world, "world"))
  groups: List[Dict[str, Any]] = list(next_world.get("groups", []))
  kept = [g for g in groups if g.get("id") != target]
  if len(kept) == len(groups):
    raise ValueError("group id not found")
  next_world["groups"] = kept
  return next_world


def group_query(world: Dict[str, Any], key: str, value: Any) -> List[Dict[str, Any]]:
  query_key = require_non_empty_string(key, "key")
  source = require_dict(world, "world")
  return [clone(g) for g in source.get("groups", []) if g.get(query_key) == value]
