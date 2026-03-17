#!/usr/bin/env python3
"""Deterministic semantic identity digest helpers."""

from __future__ import annotations

import hashlib
import json
from typing import Any


class SemanticIdentityError(ValueError):
  pass

SUPPORTED_SID_TYPES = {
  "living_xml",
  "memory_frame",
  "protocol_message",
  "replay_trace",
  "lane",
  "lane16",
  # Backward-compatible aliases used by existing fixtures/runtime.
  "agent_memory_frame",
}


def canonical_json(value: Any) -> str:
  """Return stable JSON encoding for identity hashing."""
  try:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
  except (TypeError, ValueError) as exc:
    raise SemanticIdentityError(f"value is not canonicalizable: {exc}") from exc


def compute_sid(value: Any) -> str:
  """Compute sha256 SID from canonical JSON form."""
  digest = hashlib.sha256(canonical_json(value).encode("utf-8")).hexdigest()
  return f"sha256:{digest}"


def validate_sid_type(type_name: str) -> None:
  if not isinstance(type_name, str) or type_name == "":
    raise SemanticIdentityError("type must be non-empty string")
  if type_name not in SUPPORTED_SID_TYPES:
    raise SemanticIdentityError("unsupported sid type")


def compute_typed_sid(type_name: str, canonical_form: str) -> str:
  """Compute SID from explicit type + canonical form."""
  validate_sid_type(type_name)
  if not isinstance(canonical_form, str) or canonical_form == "":
    raise SemanticIdentityError("canonical form must be non-empty string")
  return compute_sid(f"{type_name}:{canonical_form}")
