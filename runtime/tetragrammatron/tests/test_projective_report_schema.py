#!/usr/bin/env python3

import json
import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
REPORT = ROOT / 'reports' / 'phase27D-projective-time.json'
GOLDEN_HASH = ROOT / 'golden' / 'xml-projection' / 'projective-time.replay-hash'


class ProjectiveReportSchemaTests(unittest.TestCase):
  @classmethod
  def setUpClass(cls):
    subprocess.run(['bash', 'scripts/xml-projection-gate.sh'], cwd=ROOT, check=True)

  def test_report_and_hash_exist(self):
    self.assertTrue(REPORT.exists())
    self.assertTrue(GOLDEN_HASH.exists())

  def test_report_top_level_schema(self):
    payload = json.loads(REPORT.read_text(encoding='utf-8'))
    self.assertEqual(set(payload.keys()), {'v', 'authority', 'fixtures'})
    self.assertEqual(payload['v'], 'phase27D.projective_time.v0')
    self.assertEqual(payload['authority'], 'advisory')
    self.assertIsInstance(payload['fixtures'], list)
    self.assertGreaterEqual(len(payload['fixtures']), 2)

  def test_fixture_schema(self):
    payload = json.loads(REPORT.read_text(encoding='utf-8'))
    for row in payload['fixtures']:
      self.assertEqual(set(row.keys()), {'fixture', 'projective', 'p_adic'})
      self.assertIsInstance(row['fixture'], str)

      projective = row['projective']
      self.assertEqual(
        set(projective.keys()),
        {
          'a', 'b', 'c', 'discriminant', 'class', 'step_length', 'genus',
          'element_count', 'control_count', 'unit_count', 'payload_char_count'
        },
      )
      self.assertIn(projective['class'], {'hyperbolic', 'parabolic', 'elliptic'})

      padic = row['p_adic']
      self.assertEqual(set(padic.keys()), {'value', 'primes', 'trail_len', 'valuations', 'trails'})
      self.assertEqual(padic['primes'], [2, 3, 5, 7])
      self.assertIsInstance(padic['trail_len'], int)
      self.assertGreaterEqual(padic['trail_len'], 1)

      valuations = padic['valuations']
      trails = padic['trails']
      self.assertEqual(set(valuations.keys()), {'2', '3', '5', '7'})
      self.assertEqual(set(trails.keys()), {'2', '3', '5', '7'})
      for key in ('2', '3', '5', '7'):
        self.assertIsInstance(valuations[key], int)
        self.assertEqual(len(trails[key]), padic['trail_len'])


if __name__ == '__main__':
  unittest.main()
