#!/usr/bin/env python3
"""Occurrence identities (OID) and append-only chain validation."""

from __future__ import annotations

import copy
import hashlib
import re
from typing import Any, Dict, List

from .clock import clock_to_text, validate_clock
from .sid import SemanticIdentityError, canonical_json, compute_sid, validate_sid_type


SCHEMA_V = "wave27I.identity_occurrence_chain.v0"
_SID_RE = re.compile(r"^sha256:[0-9a-f]{64}$")


def _fail(message: str) -> None:
  raise SemanticIdentityError(message)


def _is_sid(value: str) -> bool:
  return bool(_SID_RE.match(value))


def compute_oid(clock: Dict[str, int], sid: str, prev_oid: str | None) -> str:
  validate_clock(clock)
  if not isinstance(sid, str) or not _is_sid(sid):
    _fail("sid invalid")
  if prev_oid is not None and (not isinstance(prev_oid, str) or not _is_sid(prev_oid)):
    _fail("prev_oid invalid")
  payload = f"{clock_to_text(clock)}:{sid}:{prev_oid or 'null'}"
  digest = hashlib.sha256(payload.encode("utf-8")).hexdigest()
  return f"sha256:{digest}"


def validate_occurrence(entry: Dict[str, Any]) -> None:
  required = {"oid", "sid", "clock", "prev_oid", "next_oid", "type"}
  if set(entry.keys()) != required:
    _fail("occurrence keyset mismatch")

  if not isinstance(entry["oid"], str) or not _is_sid(entry["oid"]):
    _fail("oid invalid")
  if not isinstance(entry["sid"], str) or not _is_sid(entry["sid"]):
    _fail("sid invalid")
  try:
    validate_sid_type(entry["type"])
  except SemanticIdentityError as exc:
    _fail(str(exc))

  validate_clock(entry["clock"])

  for key in ("prev_oid", "next_oid"):
    oid = entry[key]
    if oid is not None and (not isinstance(oid, str) or not _is_sid(oid)):
      _fail(f"{key} invalid")

  expected = compute_oid(entry["clock"], entry["sid"], entry["prev_oid"])
  if entry["oid"] != expected:
    _fail("oid mismatch")


def validate_occurrence_chain(state: Dict[str, Any]) -> None:
  required = {"v", "authority", "head_oid", "occurrences"}
  if set(state.keys()) != required:
    _fail("state keyset mismatch")
  if state["v"] != SCHEMA_V:
    _fail("state v mismatch")
  if state["authority"] != "advisory":
    _fail("state authority mismatch")
  if not isinstance(state["head_oid"], str) or not _is_sid(state["head_oid"]):
    _fail("head_oid invalid")
  if not isinstance(state["occurrences"], list) or len(state["occurrences"]) < 1:
    _fail("occurrences must be non-empty list")

  by_oid: Dict[str, Dict[str, Any]] = {}
  for entry in state["occurrences"]:
    if not isinstance(entry, dict):
      _fail("occurrence entry must be object")
    validate_occurrence(entry)
    oid = entry["oid"]
    if oid in by_oid:
      if by_oid[oid] != entry:
        _fail("duplicate oid with non-identical content")
      _fail("duplicate oid entry")
    by_oid[oid] = entry

  if state["head_oid"] not in by_oid:
    _fail("head_oid not found")
  head = by_oid[state["head_oid"]]
  if head["next_oid"] is not None:
    _fail("head occurrence must have next_oid=null")

  for oid, entry in by_oid.items():
    prev_oid = entry["prev_oid"]
    next_oid = entry["next_oid"]
    if prev_oid is not None:
      if prev_oid not in by_oid:
        _fail("prev_oid references unknown occurrence")
      if by_oid[prev_oid]["next_oid"] != oid:
        _fail("prev/next linkage mismatch")
    if next_oid is not None:
      if next_oid not in by_oid:
        _fail("next_oid references unknown occurrence")
      if by_oid[next_oid]["prev_oid"] != oid:
        _fail("next/prev linkage mismatch")

  tails = [e for e in by_oid.values() if e["prev_oid"] is None]
  heads = [e for e in by_oid.values() if e["next_oid"] is None]
  if len(tails) != 1 or len(heads) != 1:
    _fail("occurrence chain must have exactly one tail and one head")


def canonical_occurrence_chain(state: Dict[str, Any]) -> str:
  validate_occurrence_chain(state)
  return canonical_json(state)


def traverse_occurrence_chain(state: Dict[str, Any], start_oid: str, steps: int) -> List[str]:
  validate_occurrence_chain(state)
  if not isinstance(start_oid, str) or not _is_sid(start_oid):
    _fail("start_oid invalid")
  if not isinstance(steps, int) or steps < 0:
    _fail("steps must be int >= 0")
  by_oid = {entry["oid"]: entry for entry in state["occurrences"]}
  if start_oid not in by_oid:
    _fail("start_oid not found")
  out = [start_oid]
  cursor = start_oid
  for _ in range(steps):
    nxt = by_oid[cursor]["next_oid"]
    if nxt is None:
      break
    out.append(nxt)
    cursor = nxt
  return out


def replay_hash(state: Dict[str, Any]) -> str:
  validate_occurrence_chain(state)
  tails = [entry for entry in state["occurrences"] if entry["prev_oid"] is None]
  tail_oid = tails[0]["oid"]
  walk = traverse_occurrence_chain(state, tail_oid, len(state["occurrences"]))
  return compute_sid(walk)


def append_occurrence(state: Dict[str, Any], occurrence: Dict[str, Any]) -> Dict[str, Any]:
  validate_occurrence_chain(state)
  validate_occurrence(occurrence)

  next_state = copy.deepcopy(state)
  by_oid = {entry["oid"]: entry for entry in next_state["occurrences"]}
  if occurrence["oid"] in by_oid:
    if by_oid[occurrence["oid"]] != occurrence:
      _fail("duplicate oid with non-identical content")
    return next_state

  old_head_oid = next_state["head_oid"]
  old_head = by_oid[old_head_oid]
  if occurrence["prev_oid"] != old_head_oid or occurrence["next_oid"] is not None:
    _fail("append occurrence must point prev_oid at current head and next_oid=null")

  old_head["next_oid"] = occurrence["oid"]
  next_state["occurrences"].append(copy.deepcopy(occurrence))
  next_state["head_oid"] = occurrence["oid"]
  validate_occurrence_chain(next_state)
  return next_state
