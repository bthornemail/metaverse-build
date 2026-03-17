#!/usr/bin/env python3

import json
import unittest
from pathlib import Path

from runtime.tetragrammatron.identity import (
  OCCURRENCE_SCHEMA_V,
  SemanticIdentityError,
  advance_clock,
  clock_to_text,
  initial_clock,
  replay_hash,
  traverse_occurrence_chain,
  validate_clock,
  validate_occurrence_chain,
)


ROOT = Path(__file__).resolve().parents[3]


class IdentityOccurrenceTests(unittest.TestCase):
  def _load(self, rel: str):
    with open(ROOT / rel, "r", encoding="utf-8") as f:
      return json.load(f)

  def test_clock_initial_and_advance(self):
    c0 = initial_clock()
    self.assertEqual(c0, {"frame": 0, "tick": 1, "control": 0})
    c1 = advance_clock(c0)
    self.assertEqual(c1, {"frame": 0, "tick": 2, "control": 0})

  def test_clock_wrap(self):
    wrapped = advance_clock({"frame": 239, "tick": 7, "control": 59})
    self.assertEqual(wrapped, {"frame": 0, "tick": 1, "control": 0})

  def test_clock_text(self):
    text = clock_to_text({"frame": 42, "tick": 3, "control": 28})
    self.assertEqual(text, "42.3.1C")

  def test_clock_reject(self):
    with self.assertRaises(SemanticIdentityError):
      validate_clock({"frame": 0, "tick": 0, "control": 0})

  def test_occurrence_chain_accept_and_replay(self):
    state = self._load("runtime/tetragrammatron/fixtures/identity/occurrence/accept/chain-valid.json")
    validate_occurrence_chain(state)
    self.assertEqual(state["v"], OCCURRENCE_SCHEMA_V)
    tail = state["occurrences"][0]["oid"]
    walk = traverse_occurrence_chain(state, tail, 10)
    self.assertEqual(len(walk), 3)
    h1 = replay_hash(state)
    h2 = replay_hash(state)
    self.assertEqual(h1, h2)

  def test_occurrence_chain_from_wave27h_report(self):
    state = self._load("runtime/tetragrammatron/fixtures/identity/occurrence/accept/from-wave27h-report.json")
    validate_occurrence_chain(state)
    tail = state["occurrences"][0]["oid"]
    walk = traverse_occurrence_chain(state, tail, 10)
    self.assertEqual(len(walk), 2)

  def test_occurrence_reject(self):
    bad = self._load("runtime/tetragrammatron/fixtures/identity/occurrence/must-reject/bad-broken-prev-link.json")
    with self.assertRaises(SemanticIdentityError):
      validate_occurrence_chain(bad)


if __name__ == "__main__":
  unittest.main()
