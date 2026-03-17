#!/usr/bin/env python3

import unittest

from runtime.tetragrammatron.io.light_garden_sphere import (
  FRAME_COUNT,
  LightGardenSphereError,
  compute_centroid,
  decode_frame,
  encode_frame,
  encode_sphere,
  validate_frame,
)


def _sample_points():
  points = []
  for i in range(60):
    points.append([
      i + 1,
      (i * 3) % 97,
      (i * 5) % 89,
      (i * 7) % 83,
    ])
  return points


class LightGardenSphereTests(unittest.TestCase):
  def test_centroid_deterministic(self):
    points = _sample_points()
    a = compute_centroid(points)
    b = compute_centroid(points)
    self.assertEqual(a, b)
    self.assertEqual(a["denominator"], 60)

  def test_single_frame_roundtrip_lossless(self):
    points = _sample_points()
    frame = encode_frame(points, 17)
    out = decode_frame(frame)
    self.assertEqual(out, points)

  def test_all_frames_roundtrip_lossless(self):
    points = _sample_points()
    for fid in (0, 1, 2, 59, 120, 239):
      frame = encode_frame(points, fid)
      self.assertEqual(decode_frame(frame), points)

  def test_centroid_invariant_across_frames(self):
    points = _sample_points()
    c0 = encode_frame(points, 0)["centroid"]
    c1 = encode_frame(points, 137)["centroid"]
    self.assertEqual(c0, c1)

  def test_bundle_cardinality(self):
    points = _sample_points()
    bundle = encode_sphere(points)
    self.assertEqual(bundle["frame_count"], FRAME_COUNT)
    self.assertEqual(len(bundle["frames"]), FRAME_COUNT)

  def test_fail_closed_validation(self):
    points = _sample_points()
    frame = encode_frame(points, 3)
    validate_frame(frame)
    bad = dict(frame)
    bad["authority"] = "authoritative"
    with self.assertRaises(LightGardenSphereError):
      validate_frame(bad)

  def test_reject_invalid_input_shape(self):
    with self.assertRaises(LightGardenSphereError):
      encode_frame([[1, 2, 3, 4]], 0)
    with self.assertRaises(LightGardenSphereError):
      encode_frame(_sample_points(), -1)


if __name__ == "__main__":
  unittest.main()
