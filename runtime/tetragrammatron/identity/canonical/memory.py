#!/usr/bin/env python3
"""Canonical form helpers for agent-memory payloads."""

from __future__ import annotations

from typing import Any, Dict


def normalize_frame_payload(frame_payload: Dict[str, Any]) -> Dict[str, Any]:
  """Validate keyset and return canonical key-ordered payload."""
  if set(frame_payload.keys()) != {"tick", "kind", "content"}:
    raise ValueError("frame payload keyset mismatch")
  tick = frame_payload["tick"]
  kind = frame_payload["kind"]
  content = frame_payload["content"]
  if not isinstance(tick, int) or tick < 1 or tick > 7:
    raise ValueError("tick must be int in 1..7")
  if not isinstance(kind, str) or kind == "":
    raise ValueError("kind must be non-empty string")
  if not isinstance(content, dict):
    raise ValueError("content must be object")
  return {"tick": tick, "kind": kind, "content": content}
