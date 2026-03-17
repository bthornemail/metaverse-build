import unittest

from runtime.tetragrammatron.io.klein_blackboard import (
  ASCII_START,
  FULL,
  NUL,
  ROOT_CODES,
  ROOT_START,
  UPPER_BOUND,
  KleinBlackboardError,
  KleinRelationalEngine,
  RelationalMachine,
  apply_relation,
  coxeter_mask_sequence,
  decode_configuration,
  decode_point,
  encode_configuration,
  encode_point,
)


class KleinBlackboardTests(unittest.TestCase):
  def test_point_roundtrip(self) -> None:
    point = ((1, 2), (3, 4), (6, 5))
    encoded = encode_point(point)
    self.assertEqual(len(encoded), 6)
    self.assertEqual(decode_point(encoded), point)

  def test_configuration_roundtrip(self) -> None:
    points = [
      ((1, 2), (3, 4), (6, 5)),
      ((1, 2), (4, 3), (5, 6)),
    ]
    frame = encode_configuration(points, padding=4)
    self.assertEqual(frame[:4], bytes([NUL, NUL, NUL, NUL]))
    self.assertEqual(frame[4:9], bytes(ROOT_CODES))
    self.assertEqual(frame[9:11], bytes([ASCII_START, FULL]))
    self.assertEqual(decode_configuration(frame), points)

  def test_configuration_reject_missing_marker(self) -> None:
    with self.assertRaises(KleinBlackboardError):
      decode_configuration(b"\x00\x00\x3c\x3d\x3e\x3f\x40")

  def test_apply_relation_semantics(self) -> None:
    self.assertEqual(apply_relation(NUL, b"abc"), b"abc")
    self.assertEqual(apply_relation(FULL, b"\x00\xff"), b"\xff\x00")
    self.assertEqual(
      apply_relation(ROOT_START, 60),
      ("v", 60),
    )
    with self.assertRaises(KleinBlackboardError):
      apply_relation(UPPER_BOUND, b"\xb4", {"upper_bound": UPPER_BOUND})

  def test_relational_machine_parses_stream(self) -> None:
    stream = bytes(
      [
        ROOT_START, 60,  # v=60
        ROOT_START + 1, 15,  # b=15
        FULL, 0x00,  # complemented to 0xFF
        ASCII_START,
        ord("O"),
        ord("K"),
        NUL,
      ]
    )
    machine = RelationalMachine()
    state = machine.process(stream)
    self.assertIn(("v", 60), state)
    self.assertIn(("b", 15), state)
    self.assertIn(b"\xff", state)
    self.assertIn("OK", state)

  def test_relational_machine_rejects_unknown_mask(self) -> None:
    with self.assertRaises(KleinBlackboardError):
      RelationalMachine(strict=True).process(bytes([0x42, NUL]))

  def test_coxeter_sequence_and_engine(self) -> None:
    seq = coxeter_mask_sequence(3)
    self.assertTrue(len(seq) > 0)
    self.assertTrue(all(0 <= x <= 255 for x in seq))

    engine = KleinRelationalEngine()
    self.assertEqual(engine.query_masks(3), seq)
    with self.assertRaises(KleinBlackboardError):
      engine.set_mode("invalid")


if __name__ == "__main__":
  unittest.main()
