#!/usr/bin/env python3

import unittest

from runtime.tetragrammatron.io.reversible_time import (
  LINE_DELTAS,
  ReversibleTimeError,
  ReversibleTimeline,
  advance_point,
  pack_deltas,
  rewind_point,
  step_vector,
  unpack_deltas,
)


class ReversibleTimeTests(unittest.TestCase):
  def test_forward_backward_inverse_single_step(self):
    p0 = 17
    p1 = advance_point(p0, 3)
    p2 = rewind_point(p1, 3)
    self.assertEqual(p0, p2)

  def test_forward_backward_inverse_multiple_steps(self):
    tl = ReversibleTimeline(initial_point=9)
    start = tl.current_point
    tl.forward(20)
    tl.backward(20)
    self.assertEqual(tl.current_point, start)
    self.assertEqual(tl.step_index, 0)

  def test_jump_to_matches_incremental(self):
    a = ReversibleTimeline(initial_point=33)
    b = ReversibleTimeline(initial_point=33)
    a.jump_to(25)
    b.forward(25)
    self.assertEqual(a.current_point, b.current_point)
    self.assertEqual(a.step_index, b.step_index)

  def test_fork_is_independent(self):
    base = ReversibleTimeline(initial_point=12)
    base.forward(10)
    branch = base.fork()
    base.forward(5)
    branch.backward(3)
    self.assertNotEqual(base.current_point, branch.current_point)
    self.assertNotEqual(base.step_index, branch.step_index)

  def test_step_vector_is_bounded_to_15_line_space(self):
    for n in range(0, 50):
      vec = step_vector(n)
      self.assertGreaterEqual(vec["delta"], 1)
      self.assertLessEqual(vec["delta"], LINE_DELTAS)
      self.assertIn(vec["direction"], (-1, 1))
      self.assertEqual(vec["signed_delta"], vec["delta"] * vec["direction"])

  def test_pack_unpack_deltas_roundtrip(self):
    deltas = [-15, -3, 0, 4, 15]
    blob = pack_deltas(deltas)
    self.assertEqual(unpack_deltas(blob), deltas)

  def test_reject_invalid_values(self):
    with self.assertRaises(ReversibleTimeError):
      ReversibleTimeline(initial_point=0)
    with self.assertRaises(ReversibleTimeError):
      step_vector(-1)
    with self.assertRaises(ReversibleTimeError):
      pack_deltas([16])
    with self.assertRaises(ReversibleTimeError):
      unpack_deltas(bytes([31]))


if __name__ == "__main__":
  unittest.main()
