#!/usr/bin/env python3
"""Deterministic occurrence clock for Wave27I identity+occurrence ABI."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Dict

from .sid import SemanticIdentityError


@dataclass(frozen=True)
class Clock:
  frame: int
  tick: int
  control: int


def _fail(message: str) -> None:
  raise SemanticIdentityError(message)


def validate_clock(clock: Dict[str, int]) -> Clock:
  if set(clock.keys()) != {"frame", "tick", "control"}:
    _fail("clock keyset mismatch")
  frame = clock["frame"]
  tick = clock["tick"]
  control = clock["control"]
  if not isinstance(frame, int) or frame < 0 or frame > 239:
    _fail("clock frame invalid")
  if not isinstance(tick, int) or tick < 1 or tick > 7:
    _fail("clock tick invalid")
  if not isinstance(control, int) or control < 0 or control > 59:
    _fail("clock control invalid")
  return Clock(frame=frame, tick=tick, control=control)


def clock_to_text(clock: Dict[str, int]) -> str:
  c = validate_clock(clock)
  return f"{c.frame}.{c.tick}.{c.control:02X}"


def initial_clock() -> Dict[str, int]:
  return {"frame": 0, "tick": 1, "control": 0}


def advance_clock(clock: Dict[str, int]) -> Dict[str, int]:
  c = validate_clock(clock)
  tick = (c.tick % 7) + 1
  frame = c.frame
  control = c.control
  if tick == 1:
    frame = (frame + 1) % 240
    control = (control + 1) % 60
  return {"frame": frame, "tick": tick, "control": control}


def advance_clock_steps(clock: Dict[str, int], steps: int) -> Dict[str, int]:
  if not isinstance(steps, int) or steps < 0:
    _fail("steps must be int >= 0")
  out = dict(clock)
  for _ in range(steps):
    out = advance_clock(out)
  return out
