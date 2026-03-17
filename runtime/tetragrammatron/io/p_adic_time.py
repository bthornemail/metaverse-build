#!/usr/bin/env python3
"""Advisory p-adic timing model for projection-level synchronization."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, Iterable, List

from .projective_time import TimeSignature


class PAdicTimeError(ValueError):
  pass


def _is_prime(n: int) -> bool:
  if n < 2:
    return False
  if n == 2:
    return True
  if n % 2 == 0:
    return False
  d = 3
  while d * d <= n:
    if n % d == 0:
      return False
    d += 2
  return True


def v_p(value: int, prime: int) -> int:
  """p-adic valuation: exponent of prime in value."""
  if not _is_prime(prime):
    raise PAdicTimeError(f"prime must be prime: {prime}")
  if value == 0:
    return 0
  n = abs(value)
  count = 0
  while n % prime == 0:
    n //= prime
    count += 1
  return count


def p_adic_digits(value: int, prime: int, digits: int) -> List[int]:
  """Least-significant-first base-p digits for finite trail comparison."""
  if not _is_prime(prime):
    raise PAdicTimeError(f"prime must be prime: {prime}")
  if digits < 1:
    raise PAdicTimeError("digits must be >= 1")
  n = abs(value)
  out: List[int] = []
  for _ in range(digits):
    out.append(n % prime)
    n //= prime
  return out


@dataclass(frozen=True)
class PAdicClock:
  value: int
  primes: tuple[int, ...]
  trail_len: int
  trails: Dict[int, tuple[int, ...]]
  valuations: Dict[int, int]



def signature_to_clock(signature: TimeSignature, primes: Iterable[int] = (2, 3, 5, 7), trail_len: int = 8) -> PAdicClock:
  if trail_len < 1:
    raise PAdicTimeError("trail_len must be >= 1")
  prime_tuple = tuple(primes)
  if not prime_tuple:
    raise PAdicTimeError("at least one prime required")
  for p in prime_tuple:
    if not _is_prime(p):
      raise PAdicTimeError(f"invalid prime in list: {p}")

  value = signature.discriminant
  trails = {p: tuple(p_adic_digits(value, p, trail_len)) for p in prime_tuple}
  valuations = {p: v_p(value, p) for p in prime_tuple}
  return PAdicClock(
    value=value,
    primes=prime_tuple,
    trail_len=trail_len,
    trails=trails,
    valuations=valuations,
  )


def trails_match(left: PAdicClock, right: PAdicClock, min_digits: int = 4) -> bool:
  """Match when trailing digits align for all shared primes."""
  if min_digits < 1:
    raise PAdicTimeError("min_digits must be >= 1")
  if left.primes != right.primes:
    return False
  d = min(min_digits, left.trail_len, right.trail_len)
  for p in left.primes:
    if left.trails[p][:d] != right.trails[p][:d]:
      return False
  return True


def can_sync_p_adic(left: TimeSignature, right: TimeSignature, primes: Iterable[int] = (2, 3, 5, 7), min_digits: int = 4) -> bool:
  """Advisory sync predicate: same trails across configured primes."""
  l_clock = signature_to_clock(left, primes=primes, trail_len=max(min_digits, 8))
  r_clock = signature_to_clock(right, primes=primes, trail_len=max(min_digits, 8))
  return trails_match(l_clock, r_clock, min_digits=min_digits)
