#!/usr/bin/env python3
"""FS (0x1C): world/file-level pure operations."""

from __future__ import annotations

from typing import Any, Dict

from .common import clone, deterministic_id, require_dict, require_non_empty_string


def world_create(name: str, config: Dict[str, Any] | None = None) -> Dict[str, Any]:
  world_name = require_non_empty_string(name, "name")
  world_config = require_dict(config or {}, "config")
  world_id = deterministic_id("world", {"name": world_name, "config": world_config})
  return {
    "id": world_id,
    "name": world_name,
    "config": clone(world_config),
    "groups": [],
    "schema": "tetragrammatron.world.v1",
    "authority": "advisory",
  }


def world_load(world: Dict[str, Any]) -> Dict[str, Any]:
  loaded = require_dict(world, "world")
  return clone(loaded)


def world_save(world: Dict[str, Any]) -> Dict[str, Any]:
  saved = require_dict(world, "world")
  return clone(saved)
