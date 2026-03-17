#!/usr/bin/env python3

import json
import unittest
from pathlib import Path

from runtime.tetragrammatron.io.klein_blackboard import (
  KleinBlackboardError,
  min_hamming_distance,
  validate_klein_incidence,
)


ROOT = Path(__file__).resolve().parents[3]
ACCEPT_FIXTURE = ROOT / "runtime/tetragrammatron/fixtures/klein/accept/canonical-60.json"
MUST_REJECT_DIR = ROOT / "runtime/tetragrammatron/fixtures/klein/must-reject"


class KleinIncidenceTests(unittest.TestCase):
  def _load_points(self, path: Path):
    with path.open("r", encoding="utf-8") as f:
      data = json.load(f)
    self.assertEqual(data["authority"], "advisory")
    self.assertEqual(data["v"], "tetragrammatron.klein60.v0")
    return data["points"]

  def test_canonical_fixture_validates(self):
    points = self._load_points(ACCEPT_FIXTURE)
    stats = validate_klein_incidence(points)
    self.assertEqual(stats["point_count"], 60)
    self.assertEqual(stats["oriented_unique_count"], 60)
    self.assertEqual(stats["matching_class_count"], 15)
    self.assertEqual(stats["line_count"], 15)

  def test_canonical_fixture_has_minimum_distance(self):
    points = self._load_points(ACCEPT_FIXTURE)
    self.assertGreaterEqual(min_hamming_distance(points), 2)

  def test_must_reject_fixtures_fail_closed(self):
    for path in sorted(MUST_REJECT_DIR.glob("*.json")):
      with self.subTest(path=path.name):
        points = self._load_points(path)
        with self.assertRaises(KleinBlackboardError):
          validate_klein_incidence(points)


if __name__ == "__main__":
  unittest.main()
