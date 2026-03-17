#!/usr/bin/env python3

import json
import unittest
from pathlib import Path

from runtime.tetragrammatron.tools.kgc import KGCError, parse_kg


ROOT = Path(__file__).resolve().parents[3]
GRAMMAR_DIR = ROOT / "runtime/tetragrammatron/grammars"
GEN_DIR = ROOT / "runtime/tetragrammatron/generated/ast_spherepack"
MR_DIR = ROOT / "runtime/tetragrammatron/fixtures/kg/must-reject"


class KGCTests(unittest.TestCase):
  def test_python_grammar_matches_generated_mapping(self):
    text = (GRAMMAR_DIR / "python.kg").read_text(encoding="utf-8")
    compiled = parse_kg(text)
    generated = json.loads((GEN_DIR / "python.mapping.json").read_text(encoding="utf-8"))
    self.assertEqual(compiled, generated)

  def test_javascript_grammar_matches_generated_mapping(self):
    text = (GRAMMAR_DIR / "javascript.kg").read_text(encoding="utf-8")
    compiled = parse_kg(text)
    generated = json.loads((GEN_DIR / "javascript.mapping.json").read_text(encoding="utf-8"))
    self.assertEqual(compiled, generated)

  def test_must_reject_grammars(self):
    for path in sorted(MR_DIR.glob("*.kg")):
      with self.subTest(path=path.name):
        text = path.read_text(encoding="utf-8")
        with self.assertRaises(KGCError):
          parse_kg(text)


if __name__ == "__main__":
  unittest.main()
