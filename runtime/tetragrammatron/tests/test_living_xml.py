#!/usr/bin/env python3

import unittest

from runtime.tetragrammatron.io.living_xml import (
  LivingXmlError,
  advance_living_xml,
  circulation_role,
  circulation_trace,
  next_fano_tick,
  parse_living_xml,
)


class LivingXmlTests(unittest.TestCase):
  SAMPLE = (
    '<fs code="0x1C" tick="1">'
    '<gs code="0x1D">'
    '<rs code="0x1E">'
    '<us code="0x1F">alpha</us>'
    '<us code="0x1F">beta</us>'
    "</rs>"
    "</gs>"
    "</fs>"
  )

  def test_parse_living_xml_happy_path(self):
    parsed = parse_living_xml(self.SAMPLE)
    self.assertEqual(parsed["tick"], 1)
    self.assertEqual(parsed["role"], "heart.fs")
    self.assertEqual(parsed["units"], ["alpha", "beta"])
    self.assertEqual(parsed["fs"]["code"], "0x1C")
    self.assertEqual(parsed["fs"]["tick"], 1)

  def test_next_fano_tick_cycles(self):
    self.assertEqual(next_fano_tick(1), 2)
    self.assertEqual(next_fano_tick(7), 1)

  def test_advance_living_xml_updates_tick(self):
    advanced = advance_living_xml(self.SAMPLE)
    parsed = parse_living_xml(advanced)
    self.assertEqual(parsed["tick"], 2)
    self.assertEqual(parsed["role"], "arteries.gs")

  def test_circulation_trace_is_deterministic(self):
    a = circulation_trace(self.SAMPLE, 8)
    b = circulation_trace(self.SAMPLE, 8)
    self.assertEqual(a, b)
    self.assertEqual(a, [1, 2, 3, 4, 5, 6, 7, 1])

  def test_tick_defaults_to_one_when_absent(self):
    xml = (
      '<fs code="0x1C">'
      '<gs code="0x1D"><rs code="0x1E"><us code="0x1F">x</us></rs></gs>'
      "</fs>"
    )
    parsed = parse_living_xml(xml)
    self.assertEqual(parsed["tick"], 1)
    advanced = advance_living_xml(xml)
    self.assertIn('tick="2"', advanced)

  def test_rejects_bad_shape(self):
    bad = '<fs code="0x1C" tick="1"><foo /></fs>'
    with self.assertRaisesRegex(LivingXmlError, "gs"):
      parse_living_xml(bad)

  def test_rejects_bad_tick(self):
    with self.assertRaisesRegex(LivingXmlError, "tick must be in 1..7"):
      circulation_role(0)

  def test_rejects_non_terminal_us(self):
    bad = (
      '<fs code="0x1C" tick="1">'
      '<gs code="0x1D"><rs code="0x1E"><us code="0x1F"><data>nested</data></us></rs></gs>'
      "</fs>"
    )
    with self.assertRaisesRegex(LivingXmlError, "nested"):
      parse_living_xml(bad)

  def test_accepts_multi_gs_rs_us(self):
    xml = (
      '<fs code="0x1C" tick="7">'
      '<gs code="0x1D"><rs code="0x1E"><us code="0x1F">a</us><us code="0x1F">b</us></rs></gs>'
      '<gs code="0x1D"><rs code="0x1E"><us code="0x1F">c</us></rs><rs code="0x1E"><us code="0x1F">d</us></rs></gs>'
      "</fs>"
    )
    parsed = parse_living_xml(xml)
    self.assertEqual(parsed["tick"], 7)
    self.assertEqual(parsed["units"], ["a", "b", "c", "d"])

  def test_rejects_non_whitespace_us_tail(self):
    bad = (
      '<fs code="0x1C"><gs code="0x1D"><rs code="0x1E">'
      '<us code="0x1F">x</us>TEXT'
      "</rs></gs></fs>"
    )
    with self.assertRaisesRegex(LivingXmlError, "tail"):
      parse_living_xml(bad)


if __name__ == "__main__":
  unittest.main()
