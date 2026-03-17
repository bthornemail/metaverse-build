#!/usr/bin/env python3
"""Wave27K 16-lane parallel algebra runtime."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Dict, List, Sequence, Tuple

from runtime.tetragrammatron.identity import compute_typed_sid
from runtime.tetragrammatron.io.fano_scheduler import FANO_LINES
from runtime.tetragrammatron.io.seed_algebra import phase


SCHEMA_V = "wave27K.lane16.v0"
ALLOWED_STATES: Tuple[int, ...] = (0x0, 0x8, 0xC, 0xD, 0xE, 0xF)
CHANNELS: Tuple[str, ...] = ("FS", "GS", "RS", "US")
CHANNEL_BASE: Tuple[int, ...] = (0x1C, 0x1D, 0x1E, 0x1F)


class Lane16Error(ValueError):
  pass


def _fail(message: str) -> None:
  raise Lane16Error(message)


def validate_lane_index(lane_idx: int) -> int:
  if not isinstance(lane_idx, int) or lane_idx < 0 or lane_idx > 15:
    _fail("lane index must be in 0..15")
  return lane_idx


def validate_lane_state(lane_state: int) -> int:
  if not isinstance(lane_state, int):
    _fail("lane state must be int")
  if lane_state not in ALLOWED_STATES:
    _fail(f"invalid lane state: 0x{lane_state:X}")
  return lane_state


def lane_step(lane_state: int) -> int:
  state = validate_lane_state(lane_state)
  if state == 0x0:
    return 0x8
  if state == 0x8:
    return 0xC
  if state == 0xC:
    return 0xD
  if state == 0xD:
    return 0xE
  if state == 0xE:
    return 0xF
  return 0xC


def lane_phase(lane_idx: int, lane_state: int) -> int:
  """Return deterministic phase 1..7 for a lane occurrence."""
  idx = validate_lane_index(lane_idx)
  state = validate_lane_state(lane_state)
  seed = ((idx & 0xF) << 3) | (state & 0x7)
  # Wave27J phase(seed) is used as the anchor; lane/state offset avoids collapse.
  base = phase(seed)
  offset = (idx + (state & 0x3)) % 7
  return ((base + offset - 1) % 7) + 1


def lane_sid(lane_idx: int, lane_state: int) -> str:
  idx = validate_lane_index(lane_idx)
  state = validate_lane_state(lane_state)
  canonical = f"lane:{idx}:{state:04b}"
  return compute_typed_sid("lane", canonical)


def system_sid(lane_states: Sequence[int]) -> str:
  lanes = validate_lane_states(lane_states)
  canonical = "|".join(f"{state:04b}" for state in lanes)
  return compute_typed_sid("lane16", canonical)


def control_code(channel_idx: int, lane_idx: int) -> int:
  """Return channel control code for lane index.

  Note: this projection follows the FS/GS/RS/US base-offset convention.
  """
  if not isinstance(channel_idx, int) or channel_idx < 0 or channel_idx > 3:
    _fail("channel index must be in 0..3")
  idx = validate_lane_index(lane_idx)
  return CHANNEL_BASE[channel_idx] + (idx * 4)


def encode_lane_state(lane_idx: int, lane_state: int) -> List[int]:
  idx = validate_lane_index(lane_idx)
  state = validate_lane_state(lane_state)
  codes: List[int] = []
  if state & 0x8:
    codes.append(control_code(0, idx))
  if state & 0x4:
    codes.append(control_code(1, idx))
  if state & 0x2:
    codes.append(control_code(2, idx))
  if state & 0x1:
    codes.append(control_code(3, idx))
  return codes


def validate_lane_states(lane_states: Sequence[int]) -> List[int]:
  if not isinstance(lane_states, list) or len(lane_states) != 16:
    _fail("lane states must be list of length 16")
  return [validate_lane_state(state) for state in lane_states]


def _pcg_triple(a: int, b: int, c: int) -> bool:
  line_set = {tuple(sorted(line)) for line in FANO_LINES.values()}
  return tuple(sorted((a, b, c))) in line_set


def fano_pcg_check(group_lanes: Sequence[int], group_base_lane: int) -> bool:
  if not isinstance(group_lanes, list) or len(group_lanes) != 4:
    _fail("group must contain exactly 4 lane states")
  base = validate_lane_index(group_base_lane)
  if base not in (0, 4, 8, 12):
    _fail("group base lane must be one of 0,4,8,12")

  phases = [lane_phase(base + i, validate_lane_state(state)) for i, state in enumerate(group_lanes)]
  passed = False
  for observer in range(4):
    others = phases[:observer] + phases[observer + 1 :]
    if _pcg_triple(others[0], others[1], others[2]):
      passed = True
  return passed


def lane_pair_digest(lane_states: Sequence[int]) -> str:
  import hashlib

  lanes = validate_lane_states(lane_states)
  values: List[str] = []
  for i in range(16):
    for j in range(16):
      pa = lane_phase(i, lanes[i])
      pb = lane_phase(j, lanes[j])
      values.append(f"{i}:{j}:{pa}:{pb}")
  joined = "|".join(values)
  return "sha256:" + hashlib.sha256(joined.encode("utf-8")).hexdigest()


@dataclass
class Lane16System:
  lane_states: List[int]
  clock: int = 0

  def __post_init__(self) -> None:
    self.lane_states = validate_lane_states(self.lane_states)
    if not isinstance(self.clock, int) or self.clock < 0:
      _fail("clock must be int >= 0")

  @classmethod
  def init(cls, initial_states: Sequence[int] | None = None) -> "Lane16System":
    if initial_states is None:
      initial_states = [0x0] * 16
    return cls(lane_states=validate_lane_states(list(initial_states)), clock=0)

  @property
  def sid(self) -> str:
    return system_sid(self.lane_states)

  def tick(self) -> "Lane16System":
    self.clock += 1
    self.lane_states = [lane_step(state) for state in self.lane_states]
    return self

  def group_states(self, group_idx: int) -> List[int]:
    if not isinstance(group_idx, int) or group_idx < 0 or group_idx > 3:
      _fail("group index must be in 0..3")
    start = group_idx * 4
    return self.lane_states[start : start + 4]

  def sync_group(self, group_idx: int) -> bool:
    if not isinstance(group_idx, int) or group_idx < 0 or group_idx > 3:
      _fail("group index must be in 0..3")
    start = group_idx * 4
    return fano_pcg_check(self.group_states(group_idx), start)

  def sync_all(self) -> List[bool]:
    return [self.sync_group(group_idx) for group_idx in range(4)]

  def to_report(self) -> Dict[str, Any]:
    rows = []
    for idx, state in enumerate(self.lane_states):
      rows.append(
        {
          "lane": idx,
          "state": state,
          "state_bits": f"{state:04b}",
          "phase": lane_phase(idx, state),
          "sid": lane_sid(idx, state),
          "codes": encode_lane_state(idx, state),
        }
      )
    return {
      "v": SCHEMA_V,
      "authority": "advisory",
      "clock": self.clock,
      "sid": self.sid,
      "lanes": rows,
      "groups_sync": self.sync_all(),
      "pair_digest": lane_pair_digest(self.lane_states),
    }
