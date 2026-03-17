"""Canonicalization adapters for semantic identity inputs."""

from .living_xml import canonicalize as canonicalize_living_xml
from .memory import normalize_frame_payload
from .trace import canonicalize_events

__all__ = [
  "canonicalize_living_xml",
  "normalize_frame_payload",
  "canonicalize_events",
]
