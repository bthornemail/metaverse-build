#!/usr/bin/env python3
"""Wave27I semantic identity state and frame validation."""

from __future__ import annotations

import copy
import re
from typing import Any, Dict, List

from .sid import SemanticIdentityError, canonical_json, compute_typed_sid, validate_sid_type


SCHEMA_V = "wave27I.semantic_identity_state.v0"
_SID_RE = re.compile(r"^sha256:[0-9a-f]{64}$")


def _fail(message: str) -> None:
  raise SemanticIdentityError(message)


def _is_sid(value: str) -> bool:
  return bool(_SID_RE.match(value))


def build_sid_payload(obj_type: str, version: str, canonical: str) -> Dict[str, str]:
  try:
    validate_sid_type(obj_type)
  except SemanticIdentityError as exc:
    _fail(str(exc))
  if not isinstance(version, str) or version == "":
    _fail("version must be non-empty string")
  if not isinstance(canonical, str) or canonical == "":
    _fail("canonical must be non-empty string")
  return {
    "type": obj_type,
    "version": version,
    "canonical": canonical,
  }


def compute_object_sid(obj_type: str, version: str, canonical: str) -> str:
  """Compute SID from type + canonical meaning (version excluded)."""
  _ = version  # version remains required metadata but not part of SID law.
  payload = build_sid_payload(obj_type, version, canonical)
  return compute_typed_sid(payload["type"], payload["canonical"])


def validate_identity_object(obj: Dict[str, Any]) -> None:
  required = {"sid", "type", "version", "canonical", "prev_sid", "next_sid", "links"}
  if set(obj.keys()) != required:
    _fail("identity object keyset mismatch")

  if not isinstance(obj["sid"], str) or not _is_sid(obj["sid"]):
    _fail("identity sid invalid")
  for neighbor_key in ("prev_sid", "next_sid"):
    neighbor = obj[neighbor_key]
    if neighbor is not None and (not isinstance(neighbor, str) or not _is_sid(neighbor)):
      _fail(f"{neighbor_key} invalid")

  expected_sid = compute_object_sid(obj["type"], obj["version"], obj["canonical"])
  if obj["sid"] != expected_sid:
    _fail("identity sid mismatch")

  links = obj["links"]
  if not isinstance(links, dict) or set(links.keys()) != {"derived_from", "references"}:
    _fail("links keyset mismatch")
  for rel in ("derived_from", "references"):
    values = links[rel]
    if not isinstance(values, list):
      _fail(f"links.{rel} must be list")
    for sid in values:
      if not isinstance(sid, str) or not _is_sid(sid):
        _fail(f"links.{rel} sid invalid")


def validate_semantic_identity_state(state: Dict[str, Any]) -> None:
  required = {"v", "authority", "head_sid", "objects"}
  if set(state.keys()) != required:
    _fail("state keyset mismatch")
  if state["v"] != SCHEMA_V:
    _fail("state v mismatch")
  if state["authority"] != "advisory":
    _fail("state authority mismatch")
  if not isinstance(state["head_sid"], str) or not _is_sid(state["head_sid"]):
    _fail("head_sid invalid")
  if not isinstance(state["objects"], list) or len(state["objects"]) < 1:
    _fail("objects must be non-empty list")

  by_sid: Dict[str, Dict[str, Any]] = {}
  for obj in state["objects"]:
    if not isinstance(obj, dict):
      _fail("identity object must be object")
    validate_identity_object(obj)
    sid = obj["sid"]
    if sid in by_sid:
      if by_sid[sid] != obj:
        _fail("duplicate sid with non-identical content")
      _fail("duplicate sid entry")
    by_sid[sid] = obj

  if state["head_sid"] not in by_sid:
    _fail("head_sid not found in objects")

  head = by_sid[state["head_sid"]]
  if head["next_sid"] is not None:
    _fail("head object must have next_sid=null")

  for sid, obj in by_sid.items():
    prev_sid = obj["prev_sid"]
    next_sid = obj["next_sid"]

    if prev_sid is not None:
      if prev_sid not in by_sid:
        _fail("prev_sid references unknown object")
      if by_sid[prev_sid]["next_sid"] != sid:
        _fail("prev/next linkage mismatch")

    if next_sid is not None:
      if next_sid not in by_sid:
        _fail("next_sid references unknown object")
      if by_sid[next_sid]["prev_sid"] != sid:
        _fail("next/prev linkage mismatch")

    for rel in ("derived_from", "references"):
      for linked_sid in obj["links"][rel]:
        if linked_sid not in by_sid:
          _fail(f"links.{rel} references unknown object")

  tails = [o for o in by_sid.values() if o["prev_sid"] is None]
  heads = [o for o in by_sid.values() if o["next_sid"] is None]
  if len(tails) != 1 or len(heads) != 1:
    _fail("identity chain must have exactly one tail and one head")


def canonical_semantic_identity_state(state: Dict[str, Any]) -> str:
  validate_semantic_identity_state(state)
  return canonical_json(state)


def get_identity_object(state: Dict[str, Any], sid: str) -> Dict[str, Any]:
  validate_semantic_identity_state(state)
  if not isinstance(sid, str) or not _is_sid(sid):
    _fail("sid invalid")
  for obj in state["objects"]:
    if obj["sid"] == sid:
      return copy.deepcopy(obj)
  _fail("sid not found")
  raise AssertionError("unreachable")


def head_identity_sid(state: Dict[str, Any]) -> str:
  validate_semantic_identity_state(state)
  return state["head_sid"]


def traverse_identity_chain(state: Dict[str, Any], start_sid: str, steps: int) -> List[str]:
  validate_semantic_identity_state(state)
  if not isinstance(start_sid, str) or not _is_sid(start_sid):
    _fail("start_sid invalid")
  if not isinstance(steps, int) or steps < 0:
    _fail("steps must be int >= 0")

  by_sid = {obj["sid"]: obj for obj in state["objects"]}
  if start_sid not in by_sid:
    _fail("start_sid not found")

  out = [start_sid]
  cursor = start_sid
  for _ in range(steps):
    nxt = by_sid[cursor]["next_sid"]
    if nxt is None:
      break
    out.append(nxt)
    cursor = nxt
  return out
