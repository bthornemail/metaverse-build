#!/usr/bin/env python3

import unittest

from runtime.tetragrammatron.io.xml_projection import world_to_xml, xml_to_world


class XmlProjectionTests(unittest.TestCase):
  def _sample_world(self):
    return {
      "id": "world:test",
      "name": "xml-world",
      "authority": "advisory",
      "schema": "tetragrammatron.world.v1",
      "groups": [
        {
          "id": "group:alpha",
          "name": "alpha",
          "records": [
            {
              "id": "record:1",
              "data": {"hp": 10, "label": "npc", "active": True},
            }
          ],
        }
      ],
    }

  def test_world_to_xml_is_deterministic(self):
    world = self._sample_world()
    a = world_to_xml(world)
    b = world_to_xml(world)
    self.assertEqual(a, b)

  def test_world_xml_roundtrip(self):
    world = self._sample_world()
    xml = world_to_xml(world)
    decoded = xml_to_world(xml)
    self.assertEqual(decoded, world)

  def test_xml_rejects_bad_root_code(self):
    with self.assertRaisesRegex(ValueError, "root control code mismatch"):
      xml_to_world('<control code="0x1D"><world id="w" name="n" authority="advisory" schema="tetragrammatron.world.v1"><control code="0x1D"></control></world></control>')

  def test_xml_rejects_unknown_child(self):
    bad = (
      '<control code="0x1C">'
      '<world id="w" name="n" authority="advisory" schema="tetragrammatron.world.v1">'
      '<control code="0x1D"><foo /></control>'
      '</world>'
      '</control>'
    )
    with self.assertRaisesRegex(ValueError, "group"):
      xml_to_world(bad)


if __name__ == "__main__":
  unittest.main()
