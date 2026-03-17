#!/usr/bin/env python3
"""Deterministic Fano-plane round-robin lifecycle scheduler."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, List, Tuple


FANO_LINES: Dict[int, Tuple[int, int, int]] = {
  1: (1, 2, 4),
  2: (1, 3, 7),
  3: (1, 5, 6),
  4: (2, 3, 5),
  5: (2, 6, 7),
  6: (3, 4, 6),
  7: (4, 5, 7),
}


class FanoSchedulerError(ValueError):
  pass


def _require_line(line: int) -> None:
  if line not in FANO_LINES:
    raise FanoSchedulerError("line must be in 1..7")


def _require_point(point: int) -> None:
  if point < 1 or point > 7:
    raise FanoSchedulerError("point must be in 1..7")


def next_on_line(line: int, point: int) -> int:
  _require_line(line)
  _require_point(point)
  seq = FANO_LINES[line]
  if point not in seq:
    raise FanoSchedulerError(f"point {point} not on line {line}")
  idx = seq.index(point)
  return seq[(idx + 1) % 3]


@dataclass
class FanoProcess:
  process_id: str
  line: int
  point: int
  ticks: int = 0

  def tick(self) -> None:
    self.point = next_on_line(self.line, self.point)
    self.ticks += 1

  @property
  def local_phase(self) -> Dict[str, int]:
    # Rational phase in [0,1): point index / 3
    idx = FANO_LINES[self.line].index(self.point)
    return {"numerator": idx, "denominator": 3}


@dataclass
class FanoScheduler:
  current_line: int = 1
  global_ticks: int = 0
  _queues: Dict[int, List[FanoProcess]] = field(default_factory=lambda: {i: [] for i in range(1, 8)})

  def add_process(self, process_id: str, line: int, point: int | None = None) -> FanoProcess:
    _require_line(line)
    start_point = FANO_LINES[line][0] if point is None else point
    _require_point(start_point)
    if start_point not in FANO_LINES[line]:
      raise FanoSchedulerError("start point must lie on assigned line")
    proc = FanoProcess(process_id=process_id, line=line, point=start_point)
    self._queues[line].append(proc)
    return proc

  def tick(self) -> Dict[str, object]:
    _require_line(self.current_line)
    ran: List[Dict[str, object]] = []
    for proc in self._queues[self.current_line]:
      before = proc.point
      proc.tick()
      ran.append(
        {
          "process_id": proc.process_id,
          "line": proc.line,
          "before_point": before,
          "after_point": proc.point,
          "ticks": proc.ticks,
          "local_phase": proc.local_phase,
        }
      )
    active = self.current_line
    self.current_line = (self.current_line % 7) + 1
    self.global_ticks += 1
    return {
      "v": "tetragrammatron.fano_scheduler.tick.v0",
      "authority": "advisory",
      "active_line": active,
      "next_line": self.current_line,
      "global_ticks": self.global_ticks,
      "ran": ran,
    }

  def process_snapshot(self) -> List[Dict[str, object]]:
    rows: List[Dict[str, object]] = []
    for line in range(1, 8):
      for proc in self._queues[line]:
        rows.append(
          {
            "process_id": proc.process_id,
            "line": proc.line,
            "point": proc.point,
            "ticks": proc.ticks,
            "local_phase": proc.local_phase,
          }
        )
    rows.sort(key=lambda r: (r["line"], r["process_id"]))
    return rows
