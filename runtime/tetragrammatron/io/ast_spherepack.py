#!/usr/bin/env python3
"""Deterministic advisory AST sphere-packing compressor (Klein-indexed)."""

from __future__ import annotations

import ast
import hashlib
import re
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Sequence, Tuple

from runtime.tetragrammatron.pure.common import canonical_json

NODE_TYPE_IDS: Dict[str, int] = {
  "Module": 1,
  "FunctionDef": 2,
  "Return": 3,
  "Assign": 4,
  "AugAssign": 5,
  "Name": 6,
  "Constant": 7,
  "BinOp": 8,
  "UnaryOp": 9,
  "Call": 10,
  "Compare": 11,
  "BoolOp": 12,
  "If": 13,
  "For": 14,
  "While": 15,
}

INPUT_SCHEMA_V = "tetragrammatron.ast_spherepack.input.v0"
BUNDLE_SCHEMA_V = "tetragrammatron.ast_spherepack.bundle.v0"


class AstSpherepackError(ValueError):
  pass


@dataclass(frozen=True)
class FunctionRecord:
  module: str
  path: str
  name: str
  signature: Dict[str, Any]
  coords: Tuple[Tuple[int, int, int, int], ...]
  source_hash: str


@dataclass(frozen=True)
class NormalizedExpr:
  kind: str
  value: str
  children: Tuple["NormalizedExpr", ...]


def _sha256_hex(text: str) -> str:
  return hashlib.sha256(text.encode("utf-8")).hexdigest()


def _sha256_prefixed(text: str) -> str:
  return f"sha256:{_sha256_hex(text)}"


def _require_exact_keys(obj: Dict[str, Any], allowed: Sequence[str], label: str) -> None:
  got = set(obj.keys())
  expect = set(allowed)
  if got != expect:
    raise AstSpherepackError(f"{label} keyset mismatch: expected={sorted(expect)} got={sorted(got)}")


def _node_type_id(node: ast.AST) -> int:
  return NODE_TYPE_IDS.get(type(node).__name__, 0)


def _node_semantic_hash(node: ast.AST) -> int:
  ignored_scalar_fields = {"name", "id", "arg", "attr"}
  payload = {
    "type": type(node).__name__,
    "fields": {
      name: repr(value)
      for name, value in ast.iter_fields(node)
      if isinstance(value, (str, int, float, bool, type(None))) and name not in ignored_scalar_fields
    },
  }
  h = _sha256_hex(canonical_json(payload))
  return int(h[:8], 16)


KG_MAPPING_SCHEMA = "tetragrammatron.kg.mapping.v0"
KG_REQUIRED_KINDS = {"function", "return", "binop", "param", "number", "name"}
KG_REQUIRED_BINOPS = {"add", "sub", "mul", "div"}
KG_MAPPING_DIR = Path(__file__).resolve().parents[1] / "generated" / "ast_spherepack"


def _load_kg_mapping(language: str) -> Dict[str, Any]:
  path = KG_MAPPING_DIR / f"{language}.mapping.json"
  if not path.exists():
    raise AstSpherepackError(f"missing kg mapping file: {path}")
  data = json.loads(path.read_text(encoding="utf-8"))
  if not isinstance(data, dict):
    raise AstSpherepackError("kg mapping must be object")
  expected_keys = {"v", "authority", "language", "kinds", "binop_aliases"}
  if set(data.keys()) != expected_keys:
    raise AstSpherepackError(f"kg mapping keyset mismatch for {language}")
  if data["v"] != KG_MAPPING_SCHEMA:
    raise AstSpherepackError(f"kg mapping schema mismatch for {language}")
  if data["authority"] != "advisory":
    raise AstSpherepackError(f"kg mapping authority mismatch for {language}")
  if data["language"] != language:
    raise AstSpherepackError(f"kg mapping language mismatch for {language}")
  if not isinstance(data["kinds"], dict) or set(data["kinds"].keys()) != KG_REQUIRED_KINDS:
    raise AstSpherepackError(f"kg mapping kinds mismatch for {language}")
  if any(not isinstance(v, int) or v < 0 for v in data["kinds"].values()):
    raise AstSpherepackError(f"kg mapping kind ids invalid for {language}")
  if not isinstance(data["binop_aliases"], dict):
    raise AstSpherepackError(f"kg mapping binop aliases invalid for {language}")
  if set(data["binop_aliases"].values()) != KG_REQUIRED_BINOPS:
    raise AstSpherepackError(f"kg mapping binop aliases mismatch for {language}")
  return data


_LANGUAGE_MAPPINGS = {
  "python": _load_kg_mapping("python"),
  "javascript": _load_kg_mapping("javascript"),
}


def _mapping_for(language: str) -> Dict[str, Any]:
  if language not in _LANGUAGE_MAPPINGS:
    raise AstSpherepackError("unsupported language")
  return _LANGUAGE_MAPPINGS[language]


def _normalized_row(expr: NormalizedExpr, depth: int, mapping: Dict[str, Any]) -> Tuple[int, int, int, int]:
  payload = {"kind": expr.kind, "value": expr.value, "arity": len(expr.children)}
  sem = int(_sha256_hex(canonical_json(payload))[:8], 16)
  return (mapping["kinds"].get(expr.kind, 0), depth, len(expr.children), sem)


def _coords_from_normalized(expr: NormalizedExpr, mapping: Dict[str, Any], depth: int = 0) -> List[Tuple[int, int, int, int]]:
  out = [_normalized_row(expr, depth, mapping)]
  for child in expr.children:
    out.extend(_coords_from_normalized(child, mapping, depth + 1))
  return out


def _signature_for_function(fn: ast.FunctionDef) -> Dict[str, Any]:
  return {
    "args": len(fn.args.args),
    "returns_annotated": fn.returns is not None,
    "decorator_count": len(fn.decorator_list),
    "is_async": False,
  }


def _signature_for_js_function(arg_names: List[str]) -> Dict[str, Any]:
  return {
    "args": len(arg_names),
    "returns_annotated": False,
    "decorator_count": 0,
    "is_async": False,
  }


def _line_from_signature(signature: Dict[str, Any]) -> int:
  digest = _sha256_hex(canonical_json(signature))
  return (int(digest[:8], 16) % 15) + 1


def _point_from_coords(coords: Sequence[Tuple[int, int, int, int]]) -> int:
  digest = _sha256_hex(canonical_json(list(coords)))
  return (int(digest[:8], 16) % 60) + 1


def _python_expr_to_normalized(node: ast.AST, param_index: Dict[str, int], mapping: Dict[str, Any]) -> NormalizedExpr:
  if isinstance(node, ast.BinOp):
    op_name = mapping["binop_aliases"].get(type(node.op).__name__)
    if op_name is None:
      raise AstSpherepackError(f"unsupported python binop: {type(node.op).__name__}")
    return NormalizedExpr(
      kind="binop",
      value=op_name,
      children=(
        _python_expr_to_normalized(node.left, param_index, mapping),
        _python_expr_to_normalized(node.right, param_index, mapping),
      ),
    )
  if isinstance(node, ast.Name):
    if node.id in param_index:
      return NormalizedExpr(kind="param", value=str(param_index[node.id]), children=())
    return NormalizedExpr(kind="name", value=node.id, children=())
  if isinstance(node, ast.Constant):
    if isinstance(node.value, (int, float)):
      return NormalizedExpr(kind="number", value=str(node.value), children=())
    raise AstSpherepackError(f"unsupported python constant type: {type(node.value).__name__}")
  raise AstSpherepackError(f"unsupported python expression: {type(node).__name__}")


def _python_function_coords(fn: ast.FunctionDef, mapping: Dict[str, Any]) -> List[Tuple[int, int, int, int]]:
  params = [arg.arg for arg in fn.args.args]
  param_index = {name: idx for idx, name in enumerate(params)}
  if not fn.body or not isinstance(fn.body[0], ast.Return) or fn.body[0].value is None:
    raise AstSpherepackError(f"python function {fn.name} must start with return expression in v0")
  ret = _python_expr_to_normalized(fn.body[0].value, param_index, mapping)
  root = NormalizedExpr(
    kind="function",
    value=f"args:{len(params)}",
    children=(NormalizedExpr(kind="return", value="return", children=(ret,)),),
  )
  return _coords_from_normalized(root, mapping)


JS_TOKEN_RE = re.compile(r"\s*(=>|function|return|[A-Za-z_]\w*|\d+|\+|-|\*|/|\(|\)|\{|\}|,|;)\s*")


def _js_tokenize(source: str) -> List[str]:
  tokens: List[str] = []
  idx = 0
  while idx < len(source):
    m = JS_TOKEN_RE.match(source, idx)
    if not m:
      raise AstSpherepackError(f"invalid javascript token near: {source[idx:idx+20]!r}")
    tok = m.group(1)
    tokens.append(tok)
    idx = m.end()
  return tokens


def _parse_js_expr(expr: str, param_index: Dict[str, int], mapping: Dict[str, Any]) -> NormalizedExpr:
  tokens = _js_tokenize(expr)
  pos = 0

  def peek() -> str | None:
    return tokens[pos] if pos < len(tokens) else None

  def consume(expected: str | None = None) -> str:
    nonlocal pos
    if pos >= len(tokens):
      raise AstSpherepackError("unexpected end of javascript expression")
    tok = tokens[pos]
    if expected is not None and tok != expected:
      raise AstSpherepackError(f"expected token {expected!r}, got {tok!r}")
    pos += 1
    return tok

  def parse_factor() -> NormalizedExpr:
    tok = peek()
    if tok is None:
      raise AstSpherepackError("unexpected end in javascript factor")
    if tok == "(":
      consume("(")
      node = parse_expr()
      consume(")")
      return node
    if tok.isdigit():
      consume()
      return NormalizedExpr(kind="number", value=tok, children=())
    if re.match(r"^[A-Za-z_]\w*$", tok):
      consume()
      if tok in param_index:
        return NormalizedExpr(kind="param", value=str(param_index[tok]), children=())
      return NormalizedExpr(kind="name", value=tok, children=())
    raise AstSpherepackError(f"unsupported javascript factor token: {tok!r}")

  def parse_term() -> NormalizedExpr:
    node = parse_factor()
    while peek() in ("*", "/"):
      op = consume()
      rhs = parse_factor()
      alias = mapping["binop_aliases"].get(op)
      if alias is None:
        raise AstSpherepackError(f"unsupported javascript binop: {op!r}")
      node = NormalizedExpr(kind="binop", value=alias, children=(node, rhs))
    return node

  def parse_expr() -> NormalizedExpr:
    node = parse_term()
    while peek() in ("+", "-"):
      op = consume()
      rhs = parse_term()
      alias = mapping["binop_aliases"].get(op)
      if alias is None:
        raise AstSpherepackError(f"unsupported javascript binop: {op!r}")
      node = NormalizedExpr(kind="binop", value=alias, children=(node, rhs))
    return node

  root = parse_expr()
  if pos != len(tokens):
    raise AstSpherepackError(f"unexpected trailing javascript tokens: {tokens[pos:]}")
  return root


def _extract_js_function_records(path: str, source: str, module: str, mapping: Dict[str, Any]) -> List[FunctionRecord]:
  pattern = re.compile(
    r"function\s+([A-Za-z_]\w*)\s*\(([^)]*)\)\s*\{\s*return\s+([^;]+)\s*;\s*\}",
    re.DOTALL,
  )
  matches = list(pattern.finditer(source))
  if not matches:
    raise AstSpherepackError(f"javascript parse error for {path}: no supported function declarations found")

  out: List[FunctionRecord] = []
  for m in matches:
    name = m.group(1)
    args_raw = m.group(2).strip()
    expr_raw = m.group(3).strip()
    args = [a.strip() for a in args_raw.split(",") if a.strip()] if args_raw else []
    param_index = {arg: idx for idx, arg in enumerate(args)}
    expr = _parse_js_expr(expr_raw, param_index, mapping)
    root = NormalizedExpr(
      kind="function",
      value=f"args:{len(args)}",
      children=(NormalizedExpr(kind="return", value="return", children=(expr,)),),
    )
    coords = tuple(_coords_from_normalized(root, mapping))
    signature = _signature_for_js_function(args)
    source_hash = _sha256_prefixed(m.group(0))
    out.append(
      FunctionRecord(
        module=module,
        path=path,
        name=name,
        signature=signature,
        coords=coords,
        source_hash=source_hash,
      )
    )
  return out


def extract_python_functions(path: str, source: str, module: str) -> List[FunctionRecord]:
  if not isinstance(source, str):
    raise AstSpherepackError("source must be string")
  try:
    tree = ast.parse(source)
  except SyntaxError as exc:
    raise AstSpherepackError(f"python parse error for {path}: {exc}") from exc

  mapping = _mapping_for("python")
  out: List[FunctionRecord] = []
  for node in tree.body:
    if not isinstance(node, ast.FunctionDef):
      continue
    signature = _signature_for_function(node)
    coords = tuple(_python_function_coords(node, mapping))
    source_hash = _sha256_prefixed(ast.get_source_segment(source, node) or node.name)
    out.append(
      FunctionRecord(
        module=module,
        path=path,
        name=node.name,
        signature=signature,
        coords=coords,
        source_hash=source_hash,
      )
    )
  return out


def compress_python_sources(sources: Dict[str, str], module: str) -> Dict[str, Any]:
  if not isinstance(module, str) or not module.strip():
    raise AstSpherepackError("module must be non-empty string")
  if not isinstance(sources, dict) or not sources:
    raise AstSpherepackError("sources must be non-empty object")
  for key, value in sources.items():
    if not isinstance(key, str) or not key:
      raise AstSpherepackError("source path keys must be non-empty strings")
    if not isinstance(value, str):
      raise AstSpherepackError("source values must be strings")

  records: List[FunctionRecord] = []
  for path in sorted(sources.keys()):
    records.extend(extract_python_functions(path, sources[path], module))

  dedup: Dict[Tuple[int, int, str], Dict[str, Any]] = {}
  for rec in records:
    coords_json = canonical_json(list(rec.coords))
    coords_digest = _sha256_prefixed(coords_json)
    point = _point_from_coords(rec.coords)
    line = _line_from_signature(rec.signature)
    key = (point, line, coords_digest)
    if key not in dedup:
      dedup[key] = {
        "id": _sha256_prefixed(canonical_json({"point": point, "line": line, "coords_digest": coords_digest})),
        "point": point,
        "line": line,
        "coords_digest": coords_digest,
        "coords": [list(row) for row in rec.coords],
        "signature": rec.signature,
        "sources": [],
      }
    dedup[key]["sources"].append(f"{rec.path}:{rec.name}")

  entries = sorted(
    dedup.values(),
    key=lambda e: (e["point"], e["line"], e["coords_digest"], tuple(e["sources"])),
  )
  for entry in entries:
    entry["sources"] = sorted(entry["sources"])

  source_fn_count = len(records)
  unique_count = len(entries)
  dedup_ratio = 0.0 if source_fn_count == 0 else (1.0 - (unique_count / source_fn_count))

  return {
    "v": BUNDLE_SCHEMA_V,
    "authority": "advisory",
    "language": "python",
    "module": module,
    "entries": entries,
    "stats": {
      "source_function_count": source_fn_count,
      "unique_entry_count": unique_count,
      "dedup_ratio": round(dedup_ratio, 6),
    },
  }


def compress_javascript_sources(sources: Dict[str, str], module: str) -> Dict[str, Any]:
  if not isinstance(module, str) or not module.strip():
    raise AstSpherepackError("module must be non-empty string")
  if not isinstance(sources, dict) or not sources:
    raise AstSpherepackError("sources must be non-empty object")
  for key, value in sources.items():
    if not isinstance(key, str) or not key:
      raise AstSpherepackError("source path keys must be non-empty strings")
    if not isinstance(value, str):
      raise AstSpherepackError("source values must be strings")

  mapping = _mapping_for("javascript")
  records: List[FunctionRecord] = []
  for path in sorted(sources.keys()):
    records.extend(_extract_js_function_records(path, sources[path], module, mapping))

  dedup: Dict[Tuple[int, int, str], Dict[str, Any]] = {}
  for rec in records:
    coords_json = canonical_json(list(rec.coords))
    coords_digest = _sha256_prefixed(coords_json)
    point = _point_from_coords(rec.coords)
    line = _line_from_signature(rec.signature)
    key = (point, line, coords_digest)
    if key not in dedup:
      dedup[key] = {
        "id": _sha256_prefixed(canonical_json({"point": point, "line": line, "coords_digest": coords_digest})),
        "point": point,
        "line": line,
        "coords_digest": coords_digest,
        "coords": [list(row) for row in rec.coords],
        "signature": rec.signature,
        "sources": [],
      }
    dedup[key]["sources"].append(f"{rec.path}:{rec.name}")

  entries = sorted(
    dedup.values(),
    key=lambda e: (e["point"], e["line"], e["coords_digest"], tuple(e["sources"])),
  )
  for entry in entries:
    entry["sources"] = sorted(entry["sources"])

  source_fn_count = len(records)
  unique_count = len(entries)
  dedup_ratio = 0.0 if source_fn_count == 0 else (1.0 - (unique_count / source_fn_count))

  return {
    "v": BUNDLE_SCHEMA_V,
    "authority": "advisory",
    "language": "javascript",
    "module": module,
    "entries": entries,
    "stats": {
      "source_function_count": source_fn_count,
      "unique_entry_count": unique_count,
      "dedup_ratio": round(dedup_ratio, 6),
    },
  }


def compress_ast(source: str, language: str, *, module: str = "inline", path: str = "inline") -> Dict[str, Any]:
  if not isinstance(source, str) or not source.strip():
    raise AstSpherepackError("source must be non-empty string")
  if language == "python":
    bundle = compress_python_sources({path: source}, module)
  elif language == "javascript":
    bundle = compress_javascript_sources({path: source}, module)
  else:
    raise AstSpherepackError("unsupported language")
  if len(bundle["entries"]) != 1:
    raise AstSpherepackError("compress_ast requires exactly one function in source")
  entry = bundle["entries"][0]
  return {
    "v": "tetragrammatron.ast_spherepack.single.v0",
    "authority": "advisory",
    "language": language,
    "module": module,
    "point": entry["point"],
    "line": entry["line"],
    "coordinates": entry["coords"],
    "coords_digest": entry["coords_digest"],
    "signature": entry["signature"],
    "sources": entry["sources"],
  }


def expand_bundle(bundle: Dict[str, Any]) -> List[Dict[str, Any]]:
  validate_bundle(bundle)
  out: List[Dict[str, Any]] = []
  for entry in bundle["entries"]:
    out.append({
      "id": entry["id"],
      "point": entry["point"],
      "line": entry["line"],
      "stub": f"point={entry['point']} line={entry['line']} sources={len(entry['sources'])}",
      "coords_digest": entry["coords_digest"],
      "sources": list(entry["sources"]),
    })
  return out


def validate_input_payload(payload: Dict[str, Any]) -> None:
  if not isinstance(payload, dict):
    raise AstSpherepackError("input payload must be object")
  _require_exact_keys(payload, ("v", "authority", "language", "module", "sources"), "input payload")
  if payload["v"] != INPUT_SCHEMA_V:
    raise AstSpherepackError("input payload schema mismatch")
  if payload["authority"] != "advisory":
    raise AstSpherepackError("input authority must be advisory")
  if payload["language"] not in {"python", "javascript"}:
    raise AstSpherepackError("only python/javascript languages are supported in v0")
  if not isinstance(payload["module"], str) or not payload["module"].strip():
    raise AstSpherepackError("module must be non-empty string")
  if not isinstance(payload["sources"], dict) or not payload["sources"]:
    raise AstSpherepackError("sources must be non-empty object")
  for key, value in payload["sources"].items():
    if not isinstance(key, str) or not key:
      raise AstSpherepackError("source path keys must be non-empty strings")
    if not isinstance(value, str):
      raise AstSpherepackError("source values must be strings")


def validate_bundle(bundle: Dict[str, Any]) -> None:
  if not isinstance(bundle, dict):
    raise AstSpherepackError("bundle must be object")
  _require_exact_keys(bundle, ("v", "authority", "language", "module", "entries", "stats"), "bundle")
  if bundle["v"] != BUNDLE_SCHEMA_V:
    raise AstSpherepackError("bundle schema mismatch")
  if bundle["authority"] != "advisory":
    raise AstSpherepackError("bundle authority must be advisory")
  if bundle["language"] not in {"python", "javascript"}:
    raise AstSpherepackError("bundle language mismatch")
  if not isinstance(bundle["module"], str) or not bundle["module"]:
    raise AstSpherepackError("bundle module must be non-empty string")
  if not isinstance(bundle["entries"], list):
    raise AstSpherepackError("bundle entries must be list")
  if not isinstance(bundle["stats"], dict):
    raise AstSpherepackError("bundle stats must be object")

  ids = set()
  for entry in bundle["entries"]:
    _require_exact_keys(entry, ("id", "point", "line", "coords_digest", "coords", "signature", "sources"), "bundle entry")
    if entry["id"] in ids:
      raise AstSpherepackError("duplicate bundle entry id")
    ids.add(entry["id"])
    if not (1 <= int(entry["point"]) <= 60):
      raise AstSpherepackError("bundle point out of range")
    if not (1 <= int(entry["line"]) <= 15):
      raise AstSpherepackError("bundle line out of range")
    if not isinstance(entry["coords_digest"], str) or not entry["coords_digest"].startswith("sha256:"):
      raise AstSpherepackError("bundle coords_digest invalid")
    if not isinstance(entry["coords"], list) or not entry["coords"]:
      raise AstSpherepackError("bundle coords must be non-empty list")
    if not isinstance(entry["signature"], dict):
      raise AstSpherepackError("bundle signature must be object")
    if not isinstance(entry["sources"], list) or not entry["sources"]:
      raise AstSpherepackError("bundle sources must be non-empty list")
    for row in entry["coords"]:
      if not isinstance(row, list) or len(row) != 4:
        raise AstSpherepackError("each coord row must have exactly 4 numeric fields")
      if any(not isinstance(v, int) or v < 0 for v in row):
        raise AstSpherepackError("coord values must be non-negative integers")

  _require_exact_keys(bundle["stats"], ("source_function_count", "unique_entry_count", "dedup_ratio"), "bundle stats")


def compress_input_payload(payload: Dict[str, Any]) -> Dict[str, Any]:
  validate_input_payload(payload)
  if payload["language"] == "python":
    return compress_python_sources(payload["sources"], payload["module"])
  if payload["language"] == "javascript":
    return compress_javascript_sources(payload["sources"], payload["module"])
  raise AstSpherepackError("unsupported language")
