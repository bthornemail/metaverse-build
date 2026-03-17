#!/usr/bin/env python3

import json
import unittest

from runtime.tetragrammatron.io.control_superposition import (
  ControlSuperpositionError,
  canonical_control_superposition,
  validate_control_superposition,
)


class ControlSuperpositionTests(unittest.TestCase):
  def _load(self, path: str):
    with open(path, "r", encoding="utf-8") as f:
      return json.load(f)

  def test_accept_canonical_fixture(self):
    payload = self._load("runtime/tetragrammatron/fixtures/control-superposition/accept/canonical.json")
    validate_control_superposition(payload)
    out = canonical_control_superposition(payload)
    self.assertTrue(out.startswith("{"))

  def test_reject_missing_key(self):
    payload = self._load("runtime/tetragrammatron/fixtures/control-superposition/must-reject/bad-missing-key.json")
    with self.assertRaises(ControlSuperpositionError):
      validate_control_superposition(payload)

  def test_reject_bad_root_block(self):
    payload = self._load("runtime/tetragrammatron/fixtures/control-superposition/must-reject/bad-root-block.json")
    with self.assertRaises(ControlSuperpositionError):
      validate_control_superposition(payload)

  def test_reject_bad_klein_points(self):
    payload = self._load("runtime/tetragrammatron/fixtures/control-superposition/must-reject/bad-klein-count.json")
    with self.assertRaises(ControlSuperpositionError):
      validate_control_superposition(payload)


if __name__ == "__main__":
  unittest.main()
