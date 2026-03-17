#!/usr/bin/env python3
"""Deterministic tiered fuzz harness for Wave27H living XML."""

from __future__ import annotations

import argparse
import json
import random
from typing import Any, Dict, Tuple

from runtime.tetragrammatron.io.living_xml import LivingXmlError, parse_living_xml
from runtime.tetragrammatron.tools.validate_living_xml_rng import SchemaValidationError, validate as validate_rng


def _valid_xml(rng: random.Random) -> str:
  gs_count = rng.randint(1, 3)
  parts = []
  if rng.random() < 0.5:
    parts.append(f'<fs code="0x1C" tick="{rng.randint(1,7)}">')
  else:
    parts.append('<fs code="0x1C">')
  for g in range(gs_count):
    parts.append('<gs code="0x1D">')
    for r in range(rng.randint(1, 3)):
      parts.append('<rs code="0x1E">')
      for u in range(rng.randint(1, 4)):
        token = f"u{g}{r}{u}-{rng.randint(0, 999)}"
        parts.append(f'<us code="0x1F">{token}</us>')
      parts.append("</rs>")
    parts.append("</gs>")
  parts.append("</fs>")
  return "".join(parts)


def _invalid_xml(rng: random.Random) -> Tuple[str, str]:
  variant = rng.choice(
    [
      "bad_root_code",
      "bad_tick_high",
      "bad_tick_nonint",
      "bad_unknown_child",
      "bad_extra_attr",
      "bad_nested_us",
      "bad_missing_gs",
      "bad_missing_us",
      "bad_tick_on_child",
    ]
  )
  if variant == "bad_root_code":
    return ('<fs code="0x1D"><gs code="0x1D"><rs code="0x1E"><us code="0x1F">x</us></rs></gs></fs>', "code")
  if variant == "bad_tick_high":
    return ('<fs code="0x1C" tick="8"><gs code="0x1D"><rs code="0x1E"><us code="0x1F">x</us></rs></gs></fs>', "tick")
  if variant == "bad_tick_nonint":
    return ('<fs code="0x1C" tick="abc"><gs code="0x1D"><rs code="0x1E"><us code="0x1F">x</us></rs></gs></fs>', "tick")
  if variant == "bad_unknown_child":
    return ('<fs code="0x1C"><gs code="0x1D"><foo/></gs></fs>', "structure")
  if variant == "bad_extra_attr":
    return ('<fs code="0x1C" mode="x"><gs code="0x1D"><rs code="0x1E"><us code="0x1F">x</us></rs></gs></fs>', "attr")
  if variant == "bad_nested_us":
    return ('<fs code="0x1C"><gs code="0x1D"><rs code="0x1E"><us code="0x1F"><data>x</data></us></rs></gs></fs>', "terminal")
  if variant == "bad_missing_gs":
    return ('<fs code="0x1C"></fs>', "structure")
  if variant == "bad_missing_us":
    return ('<fs code="0x1C"><gs code="0x1D"><rs code="0x1E"></rs></gs></fs>', "structure")
  return ('<fs code="0x1C"><gs code="0x1D" tick="1"><rs code="0x1E"><us code="0x1F">x</us></rs></gs></fs>', "attr")


def _classify_error(text: str) -> str:
  t = text.lower()
  if "attrs mismatch" in t or " attr" in t:
    return "attr"
  if "tick" in t:
    return "tick"
  if "code" in t:
    return "code"
  if "nested" in t or "terminal" in t:
    return "terminal"
  if "invalid xml" in t or "parse" in t:
    return "xml"
  return "structure"


def run_tier(schema_path: str, tier: str, seed: int, count: int) -> Dict[str, Any]:
  rng = random.Random(seed)
  regressions = []
  expected_hist: Dict[str, int] = {}
  observed_hist: Dict[str, int] = {}
  schema_fail = 0
  parser_fail = 0

  for i in range(count):
    is_valid = (i % 3) == 0
    if is_valid:
      xml = _valid_xml(rng)
      try:
        validate_rng(schema_path, _write_tmp(xml))
      except Exception as exc:
        regressions.append({"i": i, "type": "valid_schema_fail", "err": str(exc)})
        schema_fail += 1
      try:
        parse_living_xml(xml)
      except LivingXmlError as exc:
        regressions.append({"i": i, "type": "valid_parser_fail", "err": str(exc)})
        parser_fail += 1
      continue

    xml, expected = _invalid_xml(rng)
    expected_hist[expected] = expected_hist.get(expected, 0) + 1
    try:
      validate_rng(schema_path, _write_tmp(xml))
      regressions.append({"i": i, "type": "invalid_schema_pass"})
    except SchemaValidationError as exc:
      schema_fail += 1
      klass = _classify_error(str(exc))
      observed_hist[klass] = observed_hist.get(klass, 0) + 1
    try:
      parse_living_xml(xml)
      regressions.append({"i": i, "type": "invalid_parser_pass"})
    except LivingXmlError as exc:
      parser_fail += 1
      klass = _classify_error(str(exc))
      observed_hist[klass] = observed_hist.get(klass, 0) + 1

  return {
    "tier": tier,
    "seed": seed,
    "count": count,
    "schema_failures": schema_fail,
    "parser_failures": parser_fail,
    "expected_histogram": expected_hist,
    "observed_histogram": observed_hist,
    "regression_count": len(regressions),
    "regressions": regressions[:20],
  }


def _write_tmp(xml: str) -> str:
  # Use deterministic pseudo-path by content hash in /tmp.
  import hashlib
  import os

  h = hashlib.sha256(xml.encode("utf-8")).hexdigest()
  path = f"/tmp/living-xml-fuzz-{h}.xml"
  if not os.path.exists(path):
    with open(path, "w", encoding="utf-8") as f:
      f.write(xml)
  return path


def main() -> int:
  p = argparse.ArgumentParser()
  p.add_argument("--schema", required=True)
  p.add_argument("--tier", required=True, choices=["small", "medium", "extended"])
  p.add_argument("--seed", required=True, type=int)
  p.add_argument("--count", required=True, type=int)
  args = p.parse_args()
  summary = run_tier(args.schema, args.tier, args.seed, args.count)
  print(json.dumps(summary, sort_keys=True, separators=(",", ":"), ensure_ascii=False))
  return 1 if summary["regression_count"] > 0 else 0


if __name__ == "__main__":
  raise SystemExit(main())
