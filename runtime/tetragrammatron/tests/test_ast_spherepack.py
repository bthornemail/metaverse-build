#!/usr/bin/env python3

import copy
import json
import unittest
from pathlib import Path

from runtime.tetragrammatron.io import ast_spherepack as spherepack_module
from runtime.tetragrammatron.io.ast_spherepack import (
  AstSpherepackError,
  compress_ast,
  compress_input_payload,
  compress_javascript_sources,
  compress_python_sources,
  expand_bundle,
  validate_bundle,
  validate_input_payload,
)


ROOT = Path(__file__).resolve().parents[3]
ACCEPT = ROOT / "runtime/tetragrammatron/fixtures/ast-spherepack/accept/python-sample.json"
MUST_REJECT_DIR = ROOT / "runtime/tetragrammatron/fixtures/ast-spherepack/must-reject"
X_ACCEPT_DIR = ROOT / "runtime/tetragrammatron/fixtures/ast-spherepack/crosslang/accept"
X_MUST_REJECT_DIR = ROOT / "runtime/tetragrammatron/fixtures/ast-spherepack/crosslang/must-reject"
CROSSLANG_STEMS = ("crosslang-add", "crosslang-sub", "crosslang-mul")


class AstSpherepackTests(unittest.TestCase):
  def _load_json(self, path: Path):
    with path.open("r", encoding="utf-8") as f:
      return json.load(f)

  def test_compress_is_deterministic(self):
    payload = self._load_json(ACCEPT)
    a = compress_input_payload(payload)
    b = compress_input_payload(payload)
    self.assertEqual(a, b)
    self.assertEqual(a["stats"]["source_function_count"], 3)
    self.assertEqual(a["stats"]["unique_entry_count"], 2)

  def test_expand_roundtrip_bundle_schema(self):
    payload = self._load_json(ACCEPT)
    bundle = compress_input_payload(payload)
    validate_bundle(bundle)
    expanded = expand_bundle(bundle)
    self.assertEqual(len(expanded), 2)
    self.assertTrue(all("coords_digest" in row for row in expanded))

  def test_dedup_collapses_structural_duplicates(self):
    payload = self._load_json(ACCEPT)
    bundle = compress_input_payload(payload)
    multi_source_entries = [entry for entry in bundle["entries"] if len(entry["sources"]) > 1]
    self.assertEqual(len(multi_source_entries), 1)

  def test_input_must_reject(self):
    for path in sorted(MUST_REJECT_DIR.glob("*.json")):
      with self.subTest(path=path.name):
        payload = self._load_json(path)
        with self.assertRaises(AstSpherepackError):
          validate_input_payload(payload)

  def test_javascript_bundle_path(self):
    payload = {
      "v": "tetragrammatron.ast_spherepack.input.v0",
      "authority": "advisory",
      "language": "javascript",
      "module": "demo.js",
      "sources": {"add.js": "function add(a,b){ return a + b; }"},
    }
    bundle = compress_input_payload(payload)
    self.assertEqual(bundle["language"], "javascript")
    self.assertEqual(bundle["stats"]["source_function_count"], 1)
    self.assertEqual(bundle["stats"]["unique_entry_count"], 1)

  def test_cross_language_add_maps_to_same_geometry(self):
    for stem in CROSSLANG_STEMS:
      with self.subTest(stem=stem):
        py_fixture = self._load_json(X_ACCEPT_DIR / f"{stem}.python.json")
        js_fixture = self._load_json(X_ACCEPT_DIR / f"{stem}.javascript.json")
        py = compress_ast(py_fixture["source"], "python", module=py_fixture["module"])
        js = compress_ast(js_fixture["source"], "javascript", module=js_fixture["module"])
        self.assertEqual(py["point"], js["point"])
        self.assertEqual(py["line"], js["line"])
        self.assertEqual(py["coords_digest"], js["coords_digest"])

  def test_crosslang_must_reject(self):
    for path in sorted(X_MUST_REJECT_DIR.glob("*.json")):
      with self.subTest(path=path.name):
        payload = self._load_json(path)
        with self.assertRaises(AstSpherepackError):
          compress_ast(payload["source"], payload["language"], module=payload.get("module", "x"))

  def test_generated_mapping_parity_with_manual_mapping(self):
    manual_mappings = {
      "python": {
        "v": "tetragrammatron.kg.mapping.v0",
        "authority": "advisory",
        "language": "python",
        "kinds": {"function": 100, "return": 101, "binop": 102, "param": 103, "number": 104, "name": 105},
        "binop_aliases": {"Add": "add", "Sub": "sub", "Mult": "mul", "Div": "div"},
      },
      "javascript": {
        "v": "tetragrammatron.kg.mapping.v0",
        "authority": "advisory",
        "language": "javascript",
        "kinds": {"function": 100, "return": 101, "binop": 102, "param": 103, "number": 104, "name": 105},
        "binop_aliases": {"+": "add", "-": "sub", "*": "mul", "/": "div"},
      },
    }

    original = copy.deepcopy(spherepack_module._LANGUAGE_MAPPINGS)
    try:
      spherepack_module._LANGUAGE_MAPPINGS = manual_mappings
      manual_out = {}
      for stem in CROSSLANG_STEMS:
        py_fixture = self._load_json(X_ACCEPT_DIR / f"{stem}.python.json")
        js_fixture = self._load_json(X_ACCEPT_DIR / f"{stem}.javascript.json")
        manual_out[(stem, "python")] = compress_ast(py_fixture["source"], "python", module=py_fixture["module"])
        manual_out[(stem, "javascript")] = compress_ast(js_fixture["source"], "javascript", module=js_fixture["module"])
    finally:
      spherepack_module._LANGUAGE_MAPPINGS = original

    for stem in CROSSLANG_STEMS:
      py_fixture = self._load_json(X_ACCEPT_DIR / f"{stem}.python.json")
      js_fixture = self._load_json(X_ACCEPT_DIR / f"{stem}.javascript.json")
      default_py = compress_ast(py_fixture["source"], "python", module=py_fixture["module"])
      default_js = compress_ast(js_fixture["source"], "javascript", module=js_fixture["module"])
      self.assertEqual(default_py, manual_out[(stem, "python")])
      self.assertEqual(default_js, manual_out[(stem, "javascript")])


if __name__ == "__main__":
  unittest.main()
