#!/usr/bin/env python3

import json
import unittest
from pathlib import Path

from runtime.tetragrammatron.identity import (
  SUPPORTED_SID_TYPES,
  SEMANTIC_ID_SCHEMA_V,
  SemanticIdentityError,
  canonical_semantic_identity_state,
  compute_object_sid,
  compute_sid,
  compute_typed_sid,
  get_identity_object,
  head_identity_sid,
  put_identity_object,
  traverse_identity_chain,
  validate_semantic_identity_state,
)


ROOT = Path(__file__).resolve().parents[3]


class SemanticIdentityTests(unittest.TestCase):
  def _load(self, rel: str):
    with open(ROOT / rel, "r", encoding="utf-8") as f:
      return json.load(f)

  def test_compute_sid_deterministic(self):
    payload = {"type": "living_xml", "version": "wave27H", "canonical": "{\"x\":1}"}
    self.assertEqual(compute_sid(payload), compute_sid(payload))

  def test_typed_sid_domain_and_formula(self):
    sid = compute_typed_sid("living_xml", "{\"x\":1}")
    self.assertTrue(sid.startswith("sha256:"))
    self.assertIn("living_xml", SUPPORTED_SID_TYPES)
    with self.assertRaises(SemanticIdentityError):
      compute_typed_sid("unknown_type", "{\"x\":1}")

  def test_accept_fixtures_validate(self):
    for rel in [
      "runtime/tetragrammatron/fixtures/identity/accept/minimal-single.json",
      "runtime/tetragrammatron/fixtures/identity/accept/linked-three.json",
      "runtime/tetragrammatron/fixtures/identity/accept/memory-derived.json",
    ]:
      validate_semantic_identity_state(self._load(rel))

  def test_chain_head_get_traverse(self):
    state = self._load("runtime/tetragrammatron/fixtures/identity/accept/linked-three.json")
    head = head_identity_sid(state)
    self.assertTrue(head.startswith("sha256:"))
    tail = state["objects"][0]["sid"]
    walk = traverse_identity_chain(state, tail, 10)
    self.assertGreaterEqual(len(walk), 2)
    got = get_identity_object(state, head)
    self.assertEqual(got["sid"], head)

  def test_put_identity_object_append_only(self):
    state = self._load("runtime/tetragrammatron/fixtures/identity/accept/minimal-single.json")
    old_head = state["head_sid"]
    new_obj = {
      "type": "replay_trace",
      "version": "phase27H",
      "canonical": "[{\"event\":\"tick\",\"value\":2}]",
      "prev_sid": old_head,
      "next_sid": None,
      "links": {"derived_from": [old_head], "references": []},
    }
    new_sid = compute_object_sid(new_obj["type"], new_obj["version"], new_obj["canonical"])
    new_obj["sid"] = new_sid
    next_state = put_identity_object(state, new_obj)
    self.assertEqual(next_state["head_sid"], new_sid)
    validate_semantic_identity_state(next_state)

  def test_canonical_state_deterministic(self):
    state = self._load("runtime/tetragrammatron/fixtures/identity/accept/linked-three.json")
    a = canonical_semantic_identity_state(state)
    b = canonical_semantic_identity_state(state)
    self.assertEqual(a, b)

  def test_must_reject_fixture(self):
    bad = self._load("runtime/tetragrammatron/fixtures/identity/must-reject/bad-orphan-head.json")
    with self.assertRaises(SemanticIdentityError):
      validate_semantic_identity_state(bad)

  def test_schema_version_constant(self):
    self.assertEqual(SEMANTIC_ID_SCHEMA_V, "wave27I.semantic_identity_state.v0")


if __name__ == "__main__":
  unittest.main()
