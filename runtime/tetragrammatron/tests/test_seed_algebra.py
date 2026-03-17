#!/usr/bin/env python3

import json
import unittest
from pathlib import Path

from runtime.tetragrammatron.io.seed_algebra import (
  SeedAlgebraError,
  build_seed_entity,
  closure_fixpoint,
  compose_and,
  compose_xor,
  invariant_digest,
  phase,
  validate_seed_entity,
)

ROOT = Path(__file__).resolve().parents[3]


class SeedAlgebraTests(unittest.TestCase):
  def _load(self, rel: str):
    with open(ROOT / rel, "r", encoding="utf-8") as f:
      return json.load(f)

  def test_accept_corpus(self):
    accept = ROOT / "runtime/tetragrammatron/fixtures/seed-algebra/accept"
    for path in sorted(accept.rglob("*.json")):
      payload = json.loads(path.read_text(encoding="utf-8"))
      kind = payload["kind"]
      if kind == "seed_basic":
        self.assertEqual(payload["seed"], payload["expected_seed"])
      elif kind == "closure":
        self.assertEqual(closure_fixpoint(payload["seed"]), payload["expected_header"])
      elif kind == "phase":
        self.assertEqual(phase(payload["seed"]), payload["expected_phase"])
      elif kind == "composition":
        op = payload["op"]
        if op == "xor":
          got = compose_xor(payload["a"], payload["b"])
        elif op == "and":
          got = compose_and(payload["a"], payload["b"])
        else:
          got = phase(compose_and(payload["a"], payload["b"]))
        self.assertEqual(got, payload["expected"])
      elif kind == "entity":
        validate_seed_entity(payload["entity"])
      elif kind == "invariant":
        self.assertEqual(invariant_digest(), payload["expected_digest"])
      else:
        self.fail(f"unknown fixture kind: {kind}")

  def test_must_reject(self):
    bad_seed = self._load("runtime/tetragrammatron/fixtures/seed-algebra/must-reject/seed-too-large.json")
    with self.assertRaises(SeedAlgebraError):
      _ = closure_fixpoint(bad_seed["seed"])

    bad_entity = self._load("runtime/tetragrammatron/fixtures/seed-algebra/must-reject/malformed-header.json")
    with self.assertRaises(SeedAlgebraError):
      validate_seed_entity(bad_entity["entity"])

  def test_entity_determinism(self):
    a = build_seed_entity(28, "protocol_message")
    b = build_seed_entity(28, "protocol_message")
    self.assertEqual(a, b)


if __name__ == "__main__":
  unittest.main()
