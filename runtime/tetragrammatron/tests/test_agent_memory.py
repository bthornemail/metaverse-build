#!/usr/bin/env python3

import json
import unittest
from pathlib import Path

from runtime.tetragrammatron.io.agent_memory import (
  AgentMemoryError,
  canonical_agent_memory_state,
  compute_sid,
  get_agent_frame,
  head_agent_sid,
  put_agent_frame,
  traverse_agent_memory,
  validate_agent_memory_state,
)


ROOT = Path(__file__).resolve().parents[3]


class AgentMemoryTests(unittest.TestCase):
  def _load(self, rel: str):
    with open(ROOT / rel, "r", encoding="utf-8") as f:
      return json.load(f)

  def test_compute_sid_deterministic(self):
    payload = {"tick": 1, "kind": "living_xml", "content": {"fs": {"code": "0x1C"}}}
    self.assertEqual(compute_sid(payload), compute_sid(payload))

  def test_accept_fixtures_validate(self):
    for rel in [
      "runtime/tetragrammatron/fixtures/agent-memory/accept/minimal.json",
      "runtime/tetragrammatron/fixtures/agent-memory/accept/linked-three.json",
      "runtime/tetragrammatron/fixtures/agent-memory/accept/from-living-xml.json",
    ]:
      validate_agent_memory_state(self._load(rel))

  def test_put_get_head_traverse(self):
    state = self._load("runtime/tetragrammatron/fixtures/agent-memory/accept/minimal.json")
    next_state = put_agent_frame(state, {"tick": 2, "kind": "living_xml", "content": {"fs": {"code": "0x1C", "tick": 2}}})
    validate_agent_memory_state(next_state)
    head = head_agent_sid(next_state)
    frame = get_agent_frame(next_state, head)
    self.assertEqual(frame["tick"], 2)
    path = traverse_agent_memory(next_state, next_state["frames"][0]["sid"], 8)
    self.assertGreaterEqual(len(path), 2)

  def test_canonical_state_deterministic(self):
    state = self._load("runtime/tetragrammatron/fixtures/agent-memory/accept/linked-three.json")
    a = canonical_agent_memory_state(state)
    b = canonical_agent_memory_state(state)
    self.assertEqual(a, b)

  def test_must_reject_fixture(self):
    bad = self._load("runtime/tetragrammatron/fixtures/agent-memory/must-reject/bad-orphan-head.json")
    with self.assertRaises(AgentMemoryError):
      validate_agent_memory_state(bad)


if __name__ == "__main__":
  unittest.main()
