#!/usr/bin/env python3

import json
import unittest
from pathlib import Path

from runtime.tetragrammatron.io.seed_companion import (
  SeedCompanionError,
  build_companion,
  companion_from_xml,
  companion_to_xml,
  derive_seed_from_wave27h_report,
  to_projection_metadata,
  validate_companion,
  validate_companion_wave27h_continuity,
)
from runtime.tetragrammatron.io.xml_projection import companion_xml_block, projection_metadata, world_to_xml


ROOT = Path(__file__).resolve().parents[3]


class SeedCompanionTests(unittest.TestCase):
  def _load(self, rel: str):
    with open(ROOT / rel, "r", encoding="utf-8") as f:
      return json.load(f)

  def test_build_companion_deterministic(self):
    clock = {"frame": 0, "tick": 1, "control": 0}
    a = build_companion(seed=28, obj_type="living_xml", clock=clock, prev_oid=None)
    b = build_companion(seed=28, obj_type="living_xml", clock=clock, prev_oid=None)
    self.assertEqual(a, b)

  def test_validate_companion_accept_fixture(self):
    payload = self._load("runtime/tetragrammatron/fixtures/seed-algebra/companion/accept/minimal-living-xml.json")
    validate_companion(payload)

  def test_xml_roundtrip(self):
    payload = self._load("runtime/tetragrammatron/fixtures/seed-algebra/companion/accept/minimal-living-xml.json")
    xml_text = companion_to_xml(payload)
    roundtrip = companion_from_xml(xml_text)
    self.assertEqual(payload, roundtrip)

  def test_cross_wave_continuity(self):
    report = self._load("reports/phase27H-living-xml.json")
    companion = self._load("runtime/tetragrammatron/fixtures/seed-algebra/companion/accept/from-wave27h-report.json")
    expected_seed = derive_seed_from_wave27h_report(report)
    self.assertEqual(expected_seed, companion["seed"])
    validate_companion_wave27h_continuity(report, companion)

  def test_projection_helpers(self):
    companion = self._load("runtime/tetragrammatron/fixtures/seed-algebra/companion/accept/minimal-living-xml.json")
    world = {
      "id": "w1",
      "name": "seed-world",
      "authority": "advisory",
      "schema": "tetragrammatron.world.v1",
      "groups": [{"id": "g1", "name": "group", "records": [{"id": "r1", "data": {"x": 1}}]}],
    }
    xml_text = world_to_xml(world)
    meta = projection_metadata(xml_text, companion)
    self.assertEqual(meta["seed_companion"]["companion_ref"]["sid"], companion["sid"])
    block = companion_xml_block(companion)
    self.assertIn("companion", block)

  def test_reject_fixture(self):
    payload = self._load("runtime/tetragrammatron/fixtures/seed-algebra/companion/must-reject/bad-sid-mismatch.json")
    with self.assertRaises(SeedCompanionError):
      validate_companion(payload)


if __name__ == "__main__":
  unittest.main()
