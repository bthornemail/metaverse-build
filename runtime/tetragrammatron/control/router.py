#!/usr/bin/env python3
"""Control-code router for FS/GS/RS/US pure operations."""

from __future__ import annotations

from typing import Any, Callable, Dict

from runtime.tetragrammatron.pure import (
  group_add,
  group_create,
  group_query,
  group_remove,
  record_create,
  record_delete,
  record_update,
  resolve_if_world,
  unit_get,
  unit_set,
  unit_validate,
  world_create,
  world_load,
  world_save,
)

FS = "0x1C"
GS = "0x1D"
RS = "0x1E"
US = "0x1F"

_HANDLER_TABLE: Dict[str, Dict[str, Callable[..., Any]]] = {
  FS: {
    "create": world_create,
    "load": world_load,
    "save": world_save,
  },
  GS: {
    "create": group_create,
    "add": group_add,
    "remove": group_remove,
    "query": group_query,
  },
  RS: {
    "create": record_create,
    "update": record_update,
    "delete": record_delete,
  },
  US: {
    "get": unit_get,
    "set": unit_set,
    "validate": unit_validate,
  },
}


def route(control_code: str, operation: str, *args: Any) -> Any:
  """Route a control code and operation to a pure function."""
  if control_code not in _HANDLER_TABLE:
    raise ValueError(f"unknown control_code: {control_code}")
  if operation not in _HANDLER_TABLE[control_code]:
    raise ValueError(f"unknown operation for {control_code}: {operation}")
  return _HANDLER_TABLE[control_code][operation](*args)


def route_with_resolution(control_code: str, operation: str, *args: Any) -> Any:
  """Route then resolve advisory world semantics when applicable."""
  return resolve_if_world(route(control_code, operation, *args))


def handlers() -> Dict[str, Dict[str, Callable[..., Any]]]:
  """Read-only handler map copy for inspection/testing."""
  return {code: dict(ops) for code, ops in _HANDLER_TABLE.items()}
