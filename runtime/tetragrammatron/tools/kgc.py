#!/usr/bin/env python3
"""Klein grammar compiler (kgc) v0: .kg -> deterministic mapping JSON."""

from __future__ import annotations

import argparse
from pathlib import Path
from typing import Dict

SCHEMA_V = "tetragrammatron.kg.mapping.v0"


class KGCError(ValueError):
  pass


def canonical_json(value: object) -> str:
  return __import__("json").dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def parse_kg(text: str) -> Dict[str, object]:
  language: str | None = None
  kinds: Dict[str, int] = {}
  binops: Dict[str, str] = {}

  for lineno, raw in enumerate(text.splitlines(), start=1):
    line = raw.strip()
    if not line or line.startswith("#"):
      continue

    if line.startswith("language "):
      parts = line.split()
      if len(parts) != 2:
        raise KGCError(f"line {lineno}: malformed language declaration")
      if language is not None:
        raise KGCError(f"line {lineno}: duplicate language declaration")
      language = parts[1]
      continue

    if line.startswith("kind "):
      # kind function id=100
      parts = line.split()
      if len(parts) != 3 or not parts[2].startswith("id="):
        raise KGCError(f"line {lineno}: malformed kind declaration")
      kind = parts[1]
      if kind in kinds:
        raise KGCError(f"line {lineno}: duplicate kind {kind}")
      try:
        kind_id = int(parts[2][3:])
      except ValueError as exc:
        raise KGCError(f"line {lineno}: invalid kind id") from exc
      if kind_id < 0:
        raise KGCError(f"line {lineno}: kind id must be >= 0")
      kinds[kind] = kind_id
      continue

    if line.startswith("binop "):
      # binop Add=add
      rest = line[len("binop "):]
      if "=" not in rest:
        raise KGCError(f"line {lineno}: malformed binop declaration")
      lhs, rhs = rest.split("=", 1)
      lhs = lhs.strip()
      rhs = rhs.strip()
      if not lhs or not rhs:
        raise KGCError(f"line {lineno}: malformed binop declaration")
      if lhs in binops:
        raise KGCError(f"line {lineno}: duplicate binop alias {lhs}")
      binops[lhs] = rhs
      continue

    raise KGCError(f"line {lineno}: unknown directive")

  if language is None:
    raise KGCError("missing language declaration")
  required_kinds = {"function", "return", "binop", "param", "number", "name"}
  if set(kinds) != required_kinds:
    raise KGCError(f"kind set mismatch: expected={sorted(required_kinds)} got={sorted(kinds)}")
  required_binop_aliases = {"add", "sub", "mul", "div"}
  if set(binops.values()) != required_binop_aliases:
    raise KGCError(f"binop aliases mismatch: expected={sorted(required_binop_aliases)} got={sorted(set(binops.values()))}")

  return {
    "v": SCHEMA_V,
    "authority": "advisory",
    "language": language,
    "kinds": kinds,
    "binop_aliases": binops,
  }


def compile_file(path: Path) -> Dict[str, object]:
  return parse_kg(path.read_text(encoding="utf-8"))


def main() -> int:
  ap = argparse.ArgumentParser(description="Compile .kg grammar into mapping JSON")
  ap.add_argument("grammar", help="input .kg file")
  ap.add_argument("--out", help="output path; defaults to stdout")
  args = ap.parse_args()

  mapping = compile_file(Path(args.grammar))
  rendered = canonical_json(mapping) + "\n"
  if args.out:
    Path(args.out).write_text(rendered, encoding="utf-8")
  else:
    print(rendered, end="")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
