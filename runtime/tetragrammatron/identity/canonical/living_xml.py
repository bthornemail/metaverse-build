#!/usr/bin/env python3
"""Canonical form helpers for living XML semantic identity."""

from __future__ import annotations

from runtime.tetragrammatron.io.living_xml import parse_living_xml
from runtime.tetragrammatron.identity.sid import canonical_json


def canonicalize(xml_text: str) -> str:
  """Parse and return stable canonical JSON for living XML semantics."""
  parsed = parse_living_xml(xml_text)
  return canonical_json(parsed)
