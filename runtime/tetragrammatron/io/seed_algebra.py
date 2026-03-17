#!/usr/bin/env python3
"""Wave27J seed algebra (7-bit closure, phase, and composition)."""

from __future__ import annotations

from typing import Any, Dict

from runtime.tetragrammatron.identity import compute_typed_sid


SCHEMA_V = "wave27J.seed_algebra.v0"


class SeedAlgebraError(ValueError):
  pass


def _fail(message: str) -> None:
  raise SeedAlgebraError(message)


def normalize_seed(seed: int) -> int:
  if not isinstance(seed, int):
    _fail("seed must be int")
  if seed < 0 or seed > 0x7F:
    _fail("seed must be in 0..127")
  return seed


def step_closure(seed: int) -> int:
  """One neighbor-expansion step on cyclic 7-bit ring."""
  x = normalize_seed(seed)
  left = ((x << 1) | (x >> 6)) & 0x7F
  right = ((x >> 1) | ((x & 1) << 6)) & 0x7F
  return x | left | right


def closure_fixpoint(seed: int) -> int:
  x = normalize_seed(seed)
  while True:
    y = step_closure(x)
    if y == x:
      return x
    x = y


def popcount7(seed: int) -> int:
  x = normalize_seed(seed)
  return bin(x).count("1")


def phase_from_header(header: int) -> int:
  h = normalize_seed(header)
  phase = popcount7(h) % 7
  return 7 if phase == 0 else phase


def phase(seed: int) -> int:
  return phase_from_header(closure_fixpoint(seed))


def compose_xor(a: int, b: int) -> int:
  return normalize_seed(normalize_seed(a) ^ normalize_seed(b))


def compose_and(a: int, b: int) -> int:
  return normalize_seed(normalize_seed(a) & normalize_seed(b))


def shared_phase(a: int, b: int) -> int:
  shared = compose_and(a, b)
  return phase(shared)


def build_seed_entity(seed: int, entity_type: str = "protocol_message") -> Dict[str, Any]:
  s = normalize_seed(seed)
  header = closure_fixpoint(s)
  phase_v = phase_from_header(header)
  canonical = f"{header:07b}"
  sid = compute_typed_sid(entity_type, canonical)
  return {
    "v": SCHEMA_V,
    "seed": s,
    "header": header,
    "phase": phase_v,
    "type": entity_type,
    "sid": sid,
    "canonical": canonical,
  }


def validate_seed_entity(entity: Dict[str, Any]) -> None:
  required = {"v", "seed", "header", "phase", "type", "sid", "canonical"}
  if set(entity.keys()) != required:
    _fail("entity keyset mismatch")
  if entity["v"] != SCHEMA_V:
    _fail("entity version mismatch")
  seed = normalize_seed(entity["seed"])
  header = normalize_seed(entity["header"])
  if header != closure_fixpoint(seed):
    _fail("header is not closure fixpoint of seed")
  if entity["phase"] != phase_from_header(header):
    _fail("phase mismatch")
  canonical = f"{header:07b}"
  if entity["canonical"] != canonical:
    _fail("canonical mismatch")
  expected_sid = compute_typed_sid(entity["type"], canonical)
  if entity["sid"] != expected_sid:
    _fail("sid mismatch")


def invariant_digest() -> str:
  """Deterministic digest of pi(cl(a & b)) for all seed pairs."""
  vals = [shared_phase(a, b) for a in range(128) for b in range(128)]
  # fixed-width encoding keeps digest deterministic and compact
  encoded = "".join(str(v) for v in vals)
  import hashlib
  return "sha256:" + hashlib.sha256(encoded.encode("utf-8")).hexdigest()
