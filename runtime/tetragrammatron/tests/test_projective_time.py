#!/usr/bin/env python3

import json
import unittest

from runtime.tetragrammatron.io.projective_time import can_sync, xml_time_signature
from runtime.tetragrammatron.io.xml_projection import world_to_xml


class ProjectiveTimeTests(unittest.TestCase):
  def _load_world(self, path: str):
    with open(path, 'r', encoding='utf-8') as f:
      return json.load(f)

  def test_signature_is_deterministic(self):
    world = self._load_world('runtime/tetragrammatron/fixtures/xml-projection/accept/minimal-world.json')
    xml = world_to_xml(world)
    a = xml_time_signature(xml)
    b = xml_time_signature(xml)
    self.assertEqual(a, b)

  def test_discriminant_classification_values(self):
    world = self._load_world('runtime/tetragrammatron/fixtures/xml-projection/accept/rich-world.json')
    sig = xml_time_signature(world_to_xml(world))
    self.assertIn(sig.class_name, {'hyperbolic', 'parabolic', 'elliptic'})
    self.assertGreaterEqual(sig.step_length, 0.0)
    self.assertGreaterEqual(sig.genus, 0)
    self.assertLess(sig.genus, 8)

  def test_sync_when_signature_equal(self):
    world = self._load_world('runtime/tetragrammatron/fixtures/xml-projection/accept/minimal-world.json')
    xml = world_to_xml(world)
    left = xml_time_signature(xml)
    right = xml_time_signature(xml)
    self.assertTrue(can_sync(left, right))

  def test_no_sync_when_genus_differs(self):
    w1 = self._load_world('runtime/tetragrammatron/fixtures/xml-projection/accept/minimal-world.json')
    w2 = self._load_world('runtime/tetragrammatron/fixtures/xml-projection/accept/rich-world.json')
    s1 = xml_time_signature(world_to_xml(w1))
    s2 = xml_time_signature(world_to_xml(w2))
    if s1.genus == s2.genus:
      self.skipTest('fixture genus happened to match; sync check not informative')
    self.assertFalse(can_sync(s1, s2))


if __name__ == '__main__':
  unittest.main()
