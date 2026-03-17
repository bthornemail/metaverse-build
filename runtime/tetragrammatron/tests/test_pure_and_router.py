#!/usr/bin/env python3

import unittest

from runtime.tetragrammatron.control.router import FS, GS, RS, US, route, route_with_resolution
from runtime.tetragrammatron.pure.fs import world_create


class PureAndRouterTests(unittest.TestCase):
  def test_world_create_is_deterministic(self):
    a = world_create("demo", {"theme": "alpha"})
    b = world_create("demo", {"theme": "alpha"})
    self.assertEqual(a, b)

  def test_router_fs_create(self):
    world = route(FS, "create", "demo", {"mode": "test"})
    self.assertEqual(world["name"], "demo")
    self.assertEqual(world["authority"], "advisory")

  def test_router_group_roundtrip(self):
    world = route(FS, "create", "demo", {})
    group = route(GS, "create", "citizens", {"tier": "t1"})
    updated = route(GS, "add", world, group)
    self.assertEqual(len(updated["groups"]), 1)
    self.assertEqual(len(world["groups"]), 0)

  def test_router_record_and_unit(self):
    record = route(RS, "create", {"hp": 10, "name": "npc"})
    patched = route(RS, "update", record, {"hp": 15})
    self.assertEqual(route(US, "get", patched, "hp"), 15)
    set_value = route(US, "set", patched, "zone", "north")
    self.assertTrue(route(US, "validate", set_value["data"]["zone"], "string"))

  def test_router_rejects_unknown_control_code(self):
    with self.assertRaisesRegex(ValueError, "unknown control_code"):
      route("0xFF", "create")

  def test_router_rejects_unknown_operation(self):
    with self.assertRaisesRegex(ValueError, "unknown operation"):
      route(FS, "destroy")

  def test_route_with_resolution_world_payload(self):
    resolved = route_with_resolution(FS, "create", "resolved", {"mode": "test"})
    self.assertEqual(resolved["authority"], "advisory")
    self.assertIn("epistemic", resolved)
    self.assertIn("e8_point", resolved)
    self.assertIn("octonion", resolved)
    self.assertIn("solid", resolved)
    self.assertIn("constants", resolved)
    self.assertEqual(len(resolved["e8_point"]), 8)
    self.assertEqual(len(resolved["octonion"]), 8)
    self.assertGreaterEqual(resolved["certainty"], 0.0)
    self.assertLessEqual(resolved["certainty"], 1.0)

  def test_route_with_resolution_non_world_passthrough(self):
    record = route_with_resolution(RS, "create", {"hp": 20})
    self.assertIn("id", record)
    self.assertIn("data", record)
    self.assertNotIn("epistemic", record)


if __name__ == "__main__":
  unittest.main()
