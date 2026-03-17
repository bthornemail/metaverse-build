#!/usr/bin/env python3
"""Wave27I agent-memory ABI (deterministic, append-only, fail-closed)."""

from __future__ import annotations

import copy
import json
import re
from typing import Any, Dict, List

from runtime.tetragrammatron.identity.canonical.memory import normalize_frame_payload
from runtime.tetragrammatron.identity.sid import compute_sid as compute_semantic_sid


SCHEMA_V = "wave27I.agent_memory_state.v0"
_SID_RE = re.compile(r"^sha256:[0-9a-f]{64}$")


class AgentMemoryError(ValueError):
  pass


def _fail(message: str) -> None:
  raise AgentMemoryError(message)


def _canonical(obj: Any) -> str:
  return json.dumps(obj, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def _is_sid(value: str) -> bool:
  return bool(_SID_RE.match(value))


def compute_sid(frame_payload: Dict[str, Any]) -> str:
  """Compute deterministic SID from canonical content envelope."""
  try:
    normalized = normalize_frame_payload(frame_payload)
  except ValueError as exc:
    _fail(str(exc))
  return compute_semantic_sid(normalized)


def validate_agent_memory_state(state: Dict[str, Any]) -> None:
  required = {"v", "authority", "agent_id", "head_sid", "frames"}
  if set(state.keys()) != required:
    _fail("state keyset mismatch")
  if state["v"] != SCHEMA_V:
    _fail("state v mismatch")
  if state["authority"] != "advisory":
    _fail("state authority mismatch")
  if not isinstance(state["agent_id"], str) or state["agent_id"] == "":
    _fail("agent_id must be non-empty string")
  if not isinstance(state["frames"], list) or len(state["frames"]) < 1:
    _fail("frames must be non-empty list")
  if not isinstance(state["head_sid"], str) or not _is_sid(state["head_sid"]):
    _fail("head_sid invalid")

  by_sid: Dict[str, Dict[str, Any]] = {}
  for frame in state["frames"]:
    req = {"sid", "tick", "kind", "content", "prev_sid", "next_sid"}
    if set(frame.keys()) != req:
      _fail("frame keyset mismatch")
    if not isinstance(frame["sid"], str) or not _is_sid(frame["sid"]):
      _fail("frame sid invalid")
    for neighbor_key in ("prev_sid", "next_sid"):
      neighbor = frame[neighbor_key]
      if neighbor is not None and (not isinstance(neighbor, str) or not _is_sid(neighbor)):
        _fail(f"{neighbor_key} invalid")
    payload = {"tick": frame["tick"], "kind": frame["kind"], "content": frame["content"]}
    expected_sid = compute_sid(payload)
    if frame["sid"] != expected_sid:
      _fail("frame sid mismatch")
    if frame["sid"] in by_sid:
      if by_sid[frame["sid"]] != frame:
        _fail("duplicate sid with non-identical content")
      _fail("duplicate sid entry")
    by_sid[frame["sid"]] = frame

  if state["head_sid"] not in by_sid:
    _fail("head_sid not found in frames")
  head = by_sid[state["head_sid"]]
  if head["next_sid"] is not None:
    _fail("head frame must have next_sid=null")

  for sid, frame in by_sid.items():
    prev_sid = frame["prev_sid"]
    next_sid = frame["next_sid"]
    if prev_sid is not None:
      if prev_sid not in by_sid:
        _fail("prev_sid references unknown frame")
      if by_sid[prev_sid]["next_sid"] != sid:
        _fail("prev/next linkage mismatch")
    if next_sid is not None:
      if next_sid not in by_sid:
        _fail("next_sid references unknown frame")
      if by_sid[next_sid]["prev_sid"] != sid:
        _fail("next/prev linkage mismatch")

  # Append-only chain invariant: exactly one tail (prev_sid null) and one head (next_sid null)
  tails = [f for f in by_sid.values() if f["prev_sid"] is None]
  heads = [f for f in by_sid.values() if f["next_sid"] is None]
  if len(tails) != 1 or len(heads) != 1:
    _fail("frame chain must have exactly one tail and one head")


def canonical_agent_memory_state(state: Dict[str, Any]) -> str:
  validate_agent_memory_state(state)
  return _canonical(state)


def get_agent_frame(state: Dict[str, Any], sid: str) -> Dict[str, Any]:
  validate_agent_memory_state(state)
  if not isinstance(sid, str) or not _is_sid(sid):
    _fail("sid invalid")
  for frame in state["frames"]:
    if frame["sid"] == sid:
      return copy.deepcopy(frame)
  _fail("sid not found")
  raise AssertionError("unreachable")


def head_agent_sid(state: Dict[str, Any]) -> str:
  validate_agent_memory_state(state)
  return state["head_sid"]


def traverse_agent_memory(state: Dict[str, Any], start_sid: str, steps: int) -> List[str]:
  validate_agent_memory_state(state)
  if not isinstance(start_sid, str) or not _is_sid(start_sid):
    _fail("start_sid invalid")
  if not isinstance(steps, int) or steps < 0:
    _fail("steps must be int >= 0")
  by_sid = {frame["sid"]: frame for frame in state["frames"]}
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


def put_agent_frame(state: Dict[str, Any], frame_payload: Dict[str, Any]) -> Dict[str, Any]:
  validate_agent_memory_state(state)
  sid = compute_sid(frame_payload)
  next_state = copy.deepcopy(state)
  by_sid = {frame["sid"]: frame for frame in next_state["frames"]}
  if sid in by_sid:
    existing = by_sid[sid]
    current_payload = {"tick": existing["tick"], "kind": existing["kind"], "content": existing["content"]}
    if current_payload != frame_payload:
      _fail("duplicate sid with non-identical content")
    return next_state

  old_head_sid = next_state["head_sid"]
  old_head = by_sid[old_head_sid]
  old_head["next_sid"] = sid

  new_frame = {
    "sid": sid,
    "tick": frame_payload["tick"],
    "kind": frame_payload["kind"],
    "content": frame_payload["content"],
    "prev_sid": old_head_sid,
    "next_sid": None,
  }
  next_state["frames"].append(new_frame)
  next_state["head_sid"] = sid
  validate_agent_memory_state(next_state)
  return next_state
