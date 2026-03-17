#!/usr/bin/env python3

import unittest

from runtime.tetragrammatron.io.agent_lifecycle import (
  AgentLifecycleError,
  build_agent_snapshot,
  compare_agent_snapshots,
  sid_from_source,
  validate_agent_snapshot,
)


PY_ADD = "def add(a, b):\n  return a + b\n"
JS_ADD = "function add(a, b) { return a + b; }"


class AgentLifecycleTests(unittest.TestCase):
  def test_snapshot_is_deterministic(self):
    a = build_agent_snapshot(PY_ADD, "python", step=4, observer="tester")
    b = build_agent_snapshot(PY_ADD, "python", step=4, observer="tester")
    self.assertEqual(a, b)

  def test_cross_language_keeps_geometry(self):
    py = build_agent_snapshot(PY_ADD, "python", step=1, observer="cross")
    js = build_agent_snapshot(JS_ADD, "javascript", step=1, observer="cross")
    self.assertEqual(py["identity"]["point"], js["identity"]["point"])
    self.assertEqual(py["identity"]["line"], js["identity"]["line"])
    self.assertNotEqual(py["identity"]["sid"], js["identity"]["sid"])

  def test_evolution_preserves_geometry(self):
    v1 = "def add(a,b): return a + b\n"
    v2 = "def add(x, y):\n  return x + y\n"
    s1 = build_agent_snapshot(v1, "python", step=0, observer="evo")
    s2 = build_agent_snapshot(v2, "python", step=1, observer="evo")
    cmp = compare_agent_snapshots(s1, s2)
    self.assertFalse(cmp["same_sid"])
    self.assertTrue(cmp["same_geometry"])
    self.assertEqual(cmp["state"], "evolved_preserving_geometry")

  def test_validate_rejects_schema_drift(self):
    snap = build_agent_snapshot(PY_ADD, "python", observer="drift")
    bad = dict(snap)
    bad["authority"] = "authoritative"
    with self.assertRaises(AgentLifecycleError):
      validate_agent_snapshot(bad)

  def test_sid_from_source_rejects_unsupported_language(self):
    with self.assertRaises(AgentLifecycleError):
      sid_from_source("rust", "fn add(a:i32,b:i32)->i32{a+b}")


if __name__ == "__main__":
  unittest.main()
