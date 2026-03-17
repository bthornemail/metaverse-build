#!/usr/bin/env python3
"""Canonical form helpers for replay traces."""

from __future__ import annotations

from typing import Any, Dict, List

from runtime.tetragrammatron.identity.sid import canonical_json


def canonicalize_events(events: List[Dict[str, Any]]) -> str:
  """Return stable JSON for replay trace event arrays."""
  if not isinstance(events, list):
    raise ValueError("events must be list")
  for event in events:
    if not isinstance(event, dict):
      raise ValueError("event must be object")
  return canonical_json(events)
