#!/usr/bin/env python3

import unittest

from runtime.tetragrammatron.tools.living_xml_fuzz import run_tier


class LivingXmlFuzzTests(unittest.TestCase):
  def test_small_tier_is_deterministic(self):
    schema = "runtime/tetragrammatron/schemas/living-xml.rng"
    a = run_tier(schema, "small", seed=27100, count=30)
    b = run_tier(schema, "small", seed=27100, count=30)
    self.assertEqual(a, b)
    self.assertEqual(a["regression_count"], 0)


if __name__ == "__main__":
  unittest.main()
