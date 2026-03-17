#!/usr/bin/env python3
"""Deterministic reversible time over Klein-indexed point space."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, List, Tuple

from .klein_blackboard import coxeter_mask_sequence


POINT_COUNT = 60
LINE_DELTAS = 15


class ReversibleTimeError(ValueError):
  pass


def _require_point(point: int) -> None:
  if not isinstance(point, int) or not (1 <= point <= POINT_COUNT):
    raise ReversibleTimeError(f"point must be integer in [1, {POINT_COUNT}]")


def _delta_for_step(step: int) -> int:
  if not isinstance(step, int) or step < 0:
    raise ReversibleTimeError("step must be integer >= 0")
  masks = coxeter_mask_sequence(step)
  if not masks:
    raise ReversibleTimeError("coxeter mask sequence is empty")
  return (sum(masks) % LINE_DELTAS) + 1


def _direction_for_step(step: int) -> int:
  masks = coxeter_mask_sequence(step)
  return 1 if (masks[0] % 2 == 0) else -1


def step_vector(step: int) -> Dict[str, int]:
  delta = _delta_for_step(step)
  direction = _direction_for_step(step)
  signed = delta * direction
  return {
    "step": step,
    "delta": delta,
    "direction": direction,
    "signed_delta": signed,
  }


def advance_point(point: int, step: int) -> int:
  _require_point(point)
  vec = step_vector(step)
  next_zero = ((point - 1) + vec["signed_delta"]) % POINT_COUNT
  return next_zero + 1


def rewind_point(point: int, step: int) -> int:
  _require_point(point)
  vec = step_vector(step)
  prev_zero = ((point - 1) - vec["signed_delta"]) % POINT_COUNT
  return prev_zero + 1


def pack_deltas(deltas: List[int]) -> bytes:
  if not isinstance(deltas, list):
    raise ReversibleTimeError("deltas must be list")
  if any((not isinstance(d, int)) or d < -LINE_DELTAS or d > LINE_DELTAS for d in deltas):
    raise ReversibleTimeError(f"each delta must be integer in [{-LINE_DELTAS}, {LINE_DELTAS}]")
  # Offset encoding: -15..15 -> 0..30
  return bytes([d + LINE_DELTAS for d in deltas])


def unpack_deltas(blob: bytes) -> List[int]:
  if not isinstance(blob, (bytes, bytearray)):
    raise ReversibleTimeError("blob must be bytes")
  out: List[int] = []
  for b in blob:
    if b > (2 * LINE_DELTAS):
      raise ReversibleTimeError("invalid packed delta value")
    out.append(int(b) - LINE_DELTAS)
  return out


@dataclass
class ReversibleTimeline:
  initial_point: int

  def __post_init__(self) -> None:
    _require_point(self.initial_point)
    self.current_point = self.initial_point
    self.step_index = 0
    self._history: List[Tuple[int, int]] = []  # (step_index, point_before_step)
    self._future: List[Tuple[int, int]] = []  # (step_index, point_before_step)

  def step(self) -> int:
    before = self.current_point
    self._history.append((self.step_index, before))
    self.current_point = advance_point(self.current_point, self.step_index)
    self.step_index += 1
    self._future.clear()
    return self.current_point

  def forward(self, steps: int = 1) -> int:
    if not isinstance(steps, int) or steps < 0:
      raise ReversibleTimeError("steps must be integer >= 0")
    for _ in range(steps):
      self.step()
    return self.current_point

  def backward(self, steps: int = 1) -> int:
    if not isinstance(steps, int) or steps < 0:
      raise ReversibleTimeError("steps must be integer >= 0")
    for _ in range(steps):
      if not self._history:
        raise ReversibleTimeError("cannot rewind before origin")
      prev_step_index, prev_point = self._history.pop()
      # Capture current state to allow deterministic branch inspection if needed.
      self._future.insert(0, (self.step_index, self.current_point))
      self.step_index = prev_step_index
      self.current_point = prev_point
    return self.current_point

  def jump_to(self, absolute_step: int) -> int:
    if not isinstance(absolute_step, int) or absolute_step < 0:
      raise ReversibleTimeError("absolute_step must be integer >= 0")
    while self.step_index > absolute_step:
      self.backward(1)
    while self.step_index < absolute_step:
      self.forward(1)
    return self.current_point

  def fork(self) -> "ReversibleTimeline":
    branch = ReversibleTimeline(self.initial_point)
    branch.current_point = self.current_point
    branch.step_index = self.step_index
    branch._history = list(self._history)
    branch._future = list(self._future)
    return branch

  def diff_trace(self) -> List[int]:
    out: List[int] = []
    for step_idx, _ in self._history:
      vec = step_vector(step_idx)
      out.append(vec["signed_delta"])
    return out
