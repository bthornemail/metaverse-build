#!/usr/bin/env python3

import unittest

from runtime.tetragrammatron.io.fano_scheduler import (
  FANO_LINES,
  FanoScheduler,
  FanoSchedulerError,
  next_on_line,
)


class FanoSchedulerTests(unittest.TestCase):
  def test_next_on_line_cycle(self):
    line = 1
    seq = FANO_LINES[line]
    a = seq[0]
    b = next_on_line(line, a)
    c = next_on_line(line, b)
    d = next_on_line(line, c)
    self.assertEqual((a, b, c), seq)
    self.assertEqual(d, a)

  def test_round_robin_line_rotation(self):
    s = FanoScheduler()
    seen = []
    for _ in range(7):
      tick = s.tick()
      seen.append(tick["active_line"])
    self.assertEqual(seen, [1, 2, 3, 4, 5, 6, 7])
    self.assertEqual(s.current_line, 1)

  def test_only_active_line_processes_tick(self):
    s = FanoScheduler()
    p1 = s.add_process("p1", line=1)
    p2 = s.add_process("p2", line=2)
    s.tick()  # line 1
    self.assertEqual(p1.ticks, 1)
    self.assertEqual(p2.ticks, 0)
    s.tick()  # line 2
    self.assertEqual(p2.ticks, 1)

  def test_local_phase_is_rational(self):
    s = FanoScheduler()
    p = s.add_process("p", line=3)
    self.assertEqual(p.local_phase["denominator"], 3)
    s.tick()  # line 1, process line 3 not ticked
    self.assertEqual(p.local_phase["denominator"], 3)
    s.tick()  # line 2
    s.tick()  # line 3 -> ticks now
    self.assertEqual(p.ticks, 1)
    self.assertIn(p.local_phase["numerator"], (0, 1, 2))

  def test_reject_invalid_line_or_point(self):
    s = FanoScheduler()
    with self.assertRaises(FanoSchedulerError):
      s.add_process("x", line=9)
    with self.assertRaises(FanoSchedulerError):
      s.add_process("y", line=1, point=7)  # 7 not on line 1


if __name__ == "__main__":
  unittest.main()
