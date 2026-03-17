#!/usr/bin/env python3
"""Deterministic helpers for pure control-code modules."""

from __future__ import annotations

import copy
import hashlib
import json
from typing import Any, Dict


def canonical_json(value: Any) -> str:
  """Return canonical JSON string (sorted keys, compact separators)."""
  return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def clone(value: Any) -> Any:
  """Deep-copy helper to preserve purity of input structures."""
  return copy.deepcopy(value)


def deterministic_id(prefix: str, payload: Dict[str, Any]) -> str:
  """Build deterministic id from canonical payload."""
  digest = hashlib.sha256(canonical_json(payload).encode("utf-8")).hexdigest()
  return f"{prefix}:{digest}"


def require_dict(value: Any, label: str) -> Dict[str, Any]:
  if not isinstance(value, dict):
    raise ValueError(f"{label} must be an object")
  return value


def require_non_empty_string(value: Any, label: str) -> str:
  if not isinstance(value, str) or not value.strip():
    raise ValueError(f"{label} must be a non-empty string")
  return value
