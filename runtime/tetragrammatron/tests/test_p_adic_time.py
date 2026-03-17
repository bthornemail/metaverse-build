#!/usr/bin/env python3

import json
import unittest

from runtime.tetragrammatron.io.p_adic_time import (
  PAdicTimeError,
  can_sync_p_adic,
  p_adic_digits,
  signature_to_clock,
  trails_match,
  v_p,
)
from runtime.tetragrammatron.io.projective_time import xml_time_signature
from runtime.tetragrammatron.io.xml_projection import world_to_xml


class PAdicTimeTests(unittest.TestCase):
  def _sig(self, fixture_path: str):
    with open(fixture_path, 'r', encoding='utf-8') as f:
      world = json.load(f)
    return xml_time_signature(world_to_xml(world))

  def test_v_p(self):
    self.assertEqual(v_p(72, 2), 3)
    self.assertEqual(v_p(72, 3), 2)
    self.assertEqual(v_p(72, 5), 0)

  def test_digits(self):
    # 42 = 0b101010 => least-significant bits [0,1,0,1]
    self.assertEqual(p_adic_digits(42, 2, 4), [0, 1, 0, 1])

  def test_clock_deterministic(self):
    sig = self._sig('runtime/tetragrammatron/fixtures/xml-projection/accept/minimal-world.json')
    a = signature_to_clock(sig)
    b = signature_to_clock(sig)
    self.assertEqual(a, b)

  def test_trails_match_identical(self):
    sig = self._sig('runtime/tetragrammatron/fixtures/xml-projection/accept/minimal-world.json')
    c1 = signature_to_clock(sig)
    c2 = signature_to_clock(sig)
    self.assertTrue(trails_match(c1, c2))

  def test_can_sync_p_adic_boolean(self):
    s1 = self._sig('runtime/tetragrammatron/fixtures/xml-projection/accept/minimal-world.json')
    s2 = self._sig('runtime/tetragrammatron/fixtures/xml-projection/accept/rich-world.json')
    out = can_sync_p_adic(s1, s2)
    self.assertIn(out, (True, False))

  def test_reject_non_prime(self):
    sig = self._sig('runtime/tetragrammatron/fixtures/xml-projection/accept/minimal-world.json')
    with self.assertRaises(PAdicTimeError):
      signature_to_clock(sig, primes=(4, 5))


if __name__ == '__main__':
  unittest.main()
