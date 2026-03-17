#!/usr/bin/env python3
"""Pure append-only semantic identity store operations."""

from __future__ import annotations

import copy
from typing import Any, Dict

from .frame import (
  SCHEMA_V,
  compute_object_sid,
  validate_semantic_identity_state,
)


def new_identity_state(initial_object: Dict[str, Any]) -> Dict[str, Any]:
  """Create a minimal valid state around a single identity object."""
  state = {
    "v": SCHEMA_V,
    "authority": "advisory",
    "head_sid": initial_object["sid"],
    "objects": [copy.deepcopy(initial_object)],
  }
  validate_semantic_identity_state(state)
  return state


def put_identity_object(state: Dict[str, Any], obj: Dict[str, Any]) -> Dict[str, Any]:
  """Append object to chain head if it does not already exist."""
  validate_semantic_identity_state(state)

  expected_sid = compute_object_sid(obj["type"], obj["version"], obj["canonical"])
  next_state = copy.deepcopy(state)
  by_sid = {entry["sid"]: entry for entry in next_state["objects"]}

  if expected_sid in by_sid:
    if by_sid[expected_sid] != obj:
      raise ValueError("duplicate sid with non-identical content")
    return next_state

  old_head_sid = next_state["head_sid"]
  old_head = by_sid[old_head_sid]

  if obj.get("prev_sid") != old_head_sid or obj.get("next_sid") is not None:
    raise ValueError("append object must point prev_sid at current head and next_sid=null")

  old_head["next_sid"] = expected_sid
  next_state["objects"].append(copy.deepcopy(obj))
  next_state["head_sid"] = expected_sid

  validate_semantic_identity_state(next_state)
  return next_state
