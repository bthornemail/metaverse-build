#!/usr/bin/env python3
"""Advisory Klein blackboard relational encoding over control-code masks."""

from __future__ import annotations

from dataclasses import dataclass, field
from itertools import combinations
from typing import Any, Dict, List, Sequence, Tuple


NUL = 0x00
BEL = 0x07
ESC = 0x1B
SPACE = 0x20
ROOT_START = 0x3C
ROOT_END = 0x40
ASCII_START = 0x41
META_KEY = 0x50
DEL = 0x7F
UPPER_BOUND = 0xB3
FULL = 0xFF

ROOT_CODES = [0x3C, 0x3D, 0x3E, 0x3F, 0x40]
ROOT_PARAMS = ["v", "b", "r", "k", "lambda"]
RELATION_OFFSETS = [
  (24, -256),
  (23, 128),
  (22, -128),
  (21, -128),
  (20, -128),
  (19, 64),
  (18, -64),
  (17, 32),
  (15, -32),
  (14, -32),
  (13, 16),
  (12, -16),
  (11, -16),
  (10, -16),
  (9, -16),
  (8, -16),
  (7, 8),
  (6, -8),
  (5, 4),
  (4, -4),
  (3, 3),
  (2, -2),
  (1, -1),
]
KLEIN_SYMBOLS = (1, 2, 3, 4, 5, 6)


class KleinBlackboardError(ValueError):
  pass


def encode_point(point: Sequence[Tuple[int, int]]) -> bytes:
  if len(point) != 3:
    raise KleinBlackboardError("point must contain exactly 3 line pairs")
  out: List[int] = []
  for pair in point:
    if len(pair) != 2:
      raise KleinBlackboardError("line pair must contain 2 values")
    a, b = pair
    if not (0 <= a <= 255 and 0 <= b <= 255):
      raise KleinBlackboardError("line pair values must be byte-sized")
    out.extend([a, b])
  return bytes(out)


def decode_point(data: bytes) -> Tuple[Tuple[int, int], Tuple[int, int], Tuple[int, int]]:
  if len(data) != 6:
    raise KleinBlackboardError("point encoding must be exactly 6 bytes")
  return ((data[0], data[1]), (data[2], data[3]), (data[4], data[5]))


def encode_configuration(points: Sequence[Sequence[Tuple[int, int]]], *, padding: int = UPPER_BOUND) -> bytes:
  if not (0 <= padding <= 255):
    raise KleinBlackboardError("padding must be byte-sized")
  frame = bytearray()
  frame.extend([NUL] * padding)
  frame.extend(ROOT_CODES)
  frame.extend([ASCII_START, FULL])
  for point in points:
    frame.extend(encode_point(point))
  frame.append(NUL)
  return bytes(frame)


def decode_configuration(frame: bytes) -> List[Tuple[Tuple[int, int], Tuple[int, int], Tuple[int, int]]]:
  marker = bytes([ASCII_START, FULL])
  idx = frame.find(marker)
  if idx < 0:
    raise KleinBlackboardError("missing language boundary marker 41ff")
  payload = frame[idx + 2 :]
  if not payload or payload[-1] != NUL:
    raise KleinBlackboardError("frame missing NUL terminator")
  body = payload[:-1]
  if len(body) % 6 != 0:
    raise KleinBlackboardError("point payload length must be a multiple of 6")
  points = []
  for i in range(0, len(body), 6):
    points.append(decode_point(body[i : i + 6]))
  return points


def apply_block_relation(param_idx: int, value: int) -> Tuple[str, int]:
  if not (0 <= param_idx < len(ROOT_PARAMS)):
    raise KleinBlackboardError(f"unknown block relation index: {param_idx}")
  if not (0 <= value <= 255):
    raise KleinBlackboardError("block relation value must be byte-sized")
  return (ROOT_PARAMS[param_idx], value)


def apply_relation(mask: int, data: Any, context: Dict[str, Any] | None = None) -> Any:
  ctx = context if context is not None else {}

  if mask == NUL:
    return data
  if mask == FULL:
    raw = bytes(data)
    return bytes((~b) & 0xFF for b in raw)
  if mask == SPACE:
    if not isinstance(data, (list, tuple)):
      raise KleinBlackboardError("SPACE relation expects list/tuple of byte chunks")
    return b" ".join(bytes(chunk) for chunk in data)
  if mask == META_KEY:
    transform = ctx.get("transform")
    if transform is None:
      return data
    return transform(data)
  if ROOT_START <= mask <= ROOT_END:
    return apply_block_relation(mask - ROOT_START, int(data))
  if mask == ASCII_START:
    return bytes(data).decode("ascii")
  if mask == UPPER_BOUND:
    bound = ctx.get("upper_bound", UPPER_BOUND)
    raw = bytes(data)
    if any(b > bound for b in raw):
      raise KleinBlackboardError("value exceeds upper bound")
    return raw

  raise KleinBlackboardError(f"unknown mask: 0x{mask:02x}")


def coxeter_mask_sequence(n: int) -> List[int]:
  if n < 0:
    raise KleinBlackboardError("n must be >= 0")
  seq = []
  for exp, offset in RELATION_OFFSETS:
    seq.append(((pow(n, exp, 7) + offset) & 0xFF))
  return seq


def hamming_distance(a: bytes, b: bytes) -> int:
  if len(a) != len(b):
    raise KleinBlackboardError("hamming_distance requires equal-length byte sequences")
  return sum(x != y for x, y in zip(a, b))


def min_hamming_distance(points: Sequence[Sequence[Tuple[int, int]]]) -> int:
  if len(points) < 2:
    raise KleinBlackboardError("at least two points required for distance computation")
  enc = [encode_point(point) for point in points]
  min_dist = len(enc[0]) + 1
  for i in range(len(enc)):
    for j in range(i + 1, len(enc)):
      dist = hamming_distance(enc[i], enc[j])
      if dist < min_dist:
        min_dist = dist
  return min_dist


def _normalize_line(pair: Sequence[int]) -> Tuple[int, int]:
  if len(pair) != 2:
    raise KleinBlackboardError("line pair must contain exactly 2 symbols")
  a, b = int(pair[0]), int(pair[1])
  if a == b:
    raise KleinBlackboardError("line pair symbols must be distinct")
  if a not in KLEIN_SYMBOLS or b not in KLEIN_SYMBOLS:
    raise KleinBlackboardError("line pair symbols must be within {1..6}")
  return (a, b) if a < b else (b, a)


def _point_matching_signature(point: Sequence[Sequence[int]]) -> Tuple[Tuple[int, int], Tuple[int, int], Tuple[int, int]]:
  if len(point) != 3:
    raise KleinBlackboardError("point must contain exactly 3 line pairs")
  lines = tuple(sorted(_normalize_line(pair) for pair in point))
  symbol_set = set()
  for line in lines:
    symbol_set.update(line)
  if len(symbol_set) != 6:
    raise KleinBlackboardError("point must define a perfect matching over symbols {1..6}")
  return lines


def validate_klein_incidence(points: Sequence[Sequence[Sequence[int]]]) -> Dict[str, int]:
  if len(points) != 60:
    raise KleinBlackboardError("expected exactly 60 points")

  oriented_signatures = set()
  matching_counts: Dict[Tuple[Tuple[int, int], Tuple[int, int], Tuple[int, int]], int] = {}
  line_counts: Dict[Tuple[int, int], int] = {line: 0 for line in combinations(KLEIN_SYMBOLS, 2)}
  cooccurrence: Dict[Tuple[Tuple[int, int], Tuple[int, int]], int] = {}

  for point in points:
    encoded = encode_point(point)
    if encoded in oriented_signatures:
      raise KleinBlackboardError("duplicate oriented point encoding")
    oriented_signatures.add(encoded)

    signature = _point_matching_signature(point)
    matching_counts[signature] = matching_counts.get(signature, 0) + 1

    for line in signature:
      line_counts[line] += 1
    for i in range(3):
      for j in range(i + 1, 3):
        pair = (signature[i], signature[j])
        cooccurrence[pair] = cooccurrence.get(pair, 0) + 1

  if len(matching_counts) != 15:
    raise KleinBlackboardError("expected exactly 15 perfect-matching classes")
  if set(matching_counts.values()) != {4}:
    raise KleinBlackboardError("each perfect-matching class must appear exactly 4 times")

  if set(line_counts.values()) != {12}:
    raise KleinBlackboardError("each line must appear exactly 12 times")

  all_lines = list(combinations(KLEIN_SYMBOLS, 2))
  for i, line_a in enumerate(all_lines):
    for line_b in all_lines[i + 1 :]:
      shared = bool(set(line_a) & set(line_b))
      key = (line_a, line_b) if line_a < line_b else (line_b, line_a)
      count = cooccurrence.get(key, 0)
      if shared and count != 0:
        raise KleinBlackboardError("lines that share a symbol may not co-occur in a point")
      if not shared and count != 4:
        raise KleinBlackboardError("disjoint line pairs must co-occur exactly 4 times")

  return {
    "point_count": len(points),
    "oriented_unique_count": len(oriented_signatures),
    "matching_class_count": len(matching_counts),
    "line_count": len(line_counts),
  }


@dataclass
class RelationalMachine:
  upper_bound: int = UPPER_BOUND
  strict: bool = True
  state: List[Any] = field(default_factory=list)
  context: Dict[str, Any] = field(default_factory=dict)

  def process(self, stream: bytes) -> List[Any]:
    i = 0
    self.context["upper_bound"] = self.upper_bound

    while i < len(stream):
      mask = stream[i]
      i += 1

      if mask == NUL:
        break

      if mask == FULL:
        if i >= len(stream):
          raise KleinBlackboardError("FULL mask missing payload byte")
        self.state.append(apply_relation(mask, bytes([stream[i]]), self.context))
        i += 1
        continue

      if ROOT_START <= mask <= ROOT_END:
        if i >= len(stream):
          raise KleinBlackboardError("root relation missing value byte")
        relation = apply_relation(mask, stream[i], self.context)
        self.state.append(relation)
        self.context[relation[0]] = relation[1]
        i += 1
        continue

      if mask == ASCII_START:
        chars = []
        while i < len(stream) and stream[i] != NUL:
          chars.append(stream[i])
          i += 1
        self.state.append(apply_relation(mask, bytes(chars), self.context))
        continue

      if mask == UPPER_BOUND:
        if i >= len(stream):
          raise KleinBlackboardError("upper bound mask missing bound byte")
        self.upper_bound = stream[i]
        self.context["upper_bound"] = self.upper_bound
        self.state.append(("upper_bound", self.upper_bound))
        i += 1
        continue

      if self.strict:
        raise KleinBlackboardError(f"unknown mask in stream: 0x{mask:02x}")
      self.state.append(mask)

    return self.state


@dataclass
class KleinRelationalEngine:
  mode: str = "public"

  def set_mode(self, mode: str) -> None:
    if mode not in {"public", "private"}:
      raise KleinBlackboardError("mode must be 'public' or 'private'")
    self.mode = mode

  def execute(self, stream: bytes) -> List[Any]:
    machine = RelationalMachine()
    return machine.process(stream)

  def query_masks(self, n: int) -> List[int]:
    return coxeter_mask_sequence(n)
