#!/usr/bin/env python3

import unittest

from runtime.tetragrammatron.io.perles_identity import (
  AGENT_POINTS,
  CONTROL_CODES,
  PerlesIdentityError,
  control_code_cube_model,
  perles_coord_to_index,
  perles_index_to_coord,
  sid_to_perles_anchor,
  tension_signature,
)


SID_A = "sha256:" + ("1" * 64)
SID_B = "sha256:" + ("2" * 64)


class PerlesIdentityTests(unittest.TestCase):
  def test_index_coord_roundtrip(self):
    for idx in range(AGENT_POINTS):
      coord = perles_index_to_coord(idx)
      self.assertEqual(perles_coord_to_index(coord), idx)

  def test_sid_anchor_is_deterministic(self):
    a = sid_to_perles_anchor(SID_A)
    b = sid_to_perles_anchor(SID_A)
    self.assertEqual(a, b)

  def test_sid_anchor_differs_for_distinct_sid(self):
    a = sid_to_perles_anchor(SID_A)
    b = sid_to_perles_anchor(SID_B)
    self.assertNotEqual(a["perles_index"], b["perles_index"])

  def test_tension_signature_is_bounded(self):
    sig = tension_signature(123)
    self.assertGreaterEqual(sig["time_phase"], 0)
    self.assertGreaterEqual(sig["state_phase"], 0)
    self.assertGreaterEqual(sig["agent_phase"], 0)
    self.assertGreaterEqual(sig["tension"], 0)

  def test_control_code_cube_model_has_60_points(self):
    model = control_code_cube_model()
    self.assertEqual(model["point_count"], CONTROL_CODES)
    self.assertEqual(len(model["missing_corners"]), 4)
    self.assertEqual(len(model["points"]), CONTROL_CODES)

  def test_reject_invalid_inputs(self):
    with self.assertRaises(PerlesIdentityError):
      perles_index_to_coord(27)
    with self.assertRaises(PerlesIdentityError):
      perles_coord_to_index((3, 0, 0))
    with self.assertRaises(PerlesIdentityError):
      sid_to_perles_anchor("not-a-sid")
    with self.assertRaises(PerlesIdentityError):
      tension_signature(-1)


if __name__ == "__main__":
  unittest.main()
