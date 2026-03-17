#!/usr/bin/env python3
"""Deterministic advisory agent lifecycle snapshots for 4-channel runtime."""

from __future__ import annotations

import ast
import hashlib
import re
from typing import Any, Dict, Sequence

from runtime.tetragrammatron.io.ast_spherepack import AstSpherepackError, compress_ast
from runtime.tetragrammatron.io.p_adic_time import p_adic_digits, v_p
from runtime.tetragrammatron.pure.common import canonical_json


SNAPSHOT_SCHEMA_V = "tetragrammatron.agent_lifecycle.snapshot.v0"
SUPPORTED_LANGUAGES = {"python", "javascript"}
PADIC_PRIMES = (2, 3, 5, 7, 11, 13)

_JS_TOKEN_RE = re.compile(r"\s*(=>|function|return|[A-Za-z_]\w*|\d+|\+|-|\*|/|\(|\)|\{|\}|,|;)\s*")


class AgentLifecycleError(ValueError):
  pass


def _require_exact_keys(obj: Dict[str, Any], allowed: Sequence[str], label: str) -> None:
  got = set(obj.keys())
  expect = set(allowed)
  if got != expect:
    raise AgentLifecycleError(f"{label} keyset mismatch: expected={sorted(expect)} got={sorted(got)}")


def _sha256_hex(text: str) -> str:
  return hashlib.sha256(text.encode("utf-8")).hexdigest()


def _sha256_prefixed(text: str) -> str:
  return f"sha256:{_sha256_hex(text)}"


def _normalize_python_source(source: str) -> str:
  try:
    tree = ast.parse(source)
  except SyntaxError as exc:
    raise AgentLifecycleError(f"python parse error: {exc}") from exc
  return ast.dump(tree, annotate_fields=True, include_attributes=False)


def _normalize_javascript_source(source: str) -> str:
  tokens = []
  idx = 0
  while idx < len(source):
    match = _JS_TOKEN_RE.match(source, idx)
    if not match:
      raise AgentLifecycleError(f"invalid javascript token near: {source[idx:idx+20]!r}")
    tokens.append(match.group(1))
    idx = match.end()
  if not tokens:
    raise AgentLifecycleError("javascript source has no tokens")
  return " ".join(tokens)


def canonical_source(language: str, source: str) -> str:
  if language not in SUPPORTED_LANGUAGES:
    raise AgentLifecycleError("unsupported language")
  if not isinstance(source, str) or not source.strip():
    raise AgentLifecycleError("source must be non-empty string")
  if language == "python":
    return _normalize_python_source(source)
  return _normalize_javascript_source(source)


def sid_from_source(language: str, source: str) -> str:
  normal_form = canonical_source(language, source)
  preimage = canonical_json({"language": language, "normal_form": normal_form})
  return _sha256_prefixed(preimage)


def _sid_hex(sid: str) -> str:
  if not isinstance(sid, str) or not sid.startswith("sha256:"):
    raise AgentLifecycleError("sid must be sha256:*")
  hex_part = sid.split(":", 1)[1]
  if len(hex_part) != 64 or any(ch not in "0123456789abcdef" for ch in hex_part):
    raise AgentLifecycleError("sid hex digest invalid")
  return hex_part


def _select_prime(sid: str) -> int:
  digest = _sid_hex(sid)
  selector = int(digest[:8], 16)
  return PADIC_PRIMES[selector % len(PADIC_PRIMES)]


def _pua_codepoint(point: int, line: int) -> str:
  cp = 0xE000 + (point * 256) + line
  if cp > 0x10FFFF:
    raise AgentLifecycleError("computed PUA codepoint out of Unicode range")
  return f"U+{cp:04X}"


def build_agent_snapshot(
  source: str,
  language: str,
  *,
  step: int = 0,
  observer: str = "anonymous",
  module: str = "inline",
  path: str = "inline",
) -> Dict[str, Any]:
  if language not in SUPPORTED_LANGUAGES:
    raise AgentLifecycleError("unsupported language")
  if not isinstance(step, int) or step < 0:
    raise AgentLifecycleError("step must be integer >= 0")
  if not isinstance(observer, str) or not observer.strip():
    raise AgentLifecycleError("observer must be non-empty string")

  source_hash = _sha256_prefixed(source)
  sid = sid_from_source(language, source)
  normal_form = canonical_source(language, source)
  normal_form_hash = _sha256_prefixed(normal_form)

  try:
    geometry = compress_ast(source, language, module=module, path=path)
  except AstSpherepackError as exc:
    raise AgentLifecycleError(str(exc)) from exc

  point = int(geometry["point"])
  line = int(geometry["line"])
  prime = _select_prime(sid)

  sid_seed = int(_sid_hex(sid)[:16], 16) + 1
  p_adic_value = sid_seed + step
  p_trail = p_adic_digits(p_adic_value, prime, 8)
  p_val = v_p(p_adic_value, prime)
  frame_discriminant = (point * line) - step
  frequency_numerator = (line * (step + 1)) % 15

  snapshot = {
    "v": SNAPSHOT_SCHEMA_V,
    "authority": "advisory",
    "observer": observer,
    "identity": {
      "sid": sid,
      "point": point,
      "line": line,
      "pua_codepoint": _pua_codepoint(point, line),
    },
    "channels": {
      "binary": {
        "source_sha256": source_hash,
        "normal_form_sha256": normal_form_hash,
      },
      "decimal": {
        "sid": sid,
        "sid_u64_mod": int(_sid_hex(sid)[:16], 16),
      },
      "hex": {
        "module": geometry["module"],
        "language": geometry["language"],
        "point": point,
        "line": line,
        "coords_digest": geometry["coords_digest"],
      },
      "sign": {
        "p_adic": {
          "prime": prime,
          "value": p_adic_value,
          "valuation": p_val,
          "trail": p_trail,
        },
        "frame": {
          "step": step,
          "discriminant": frame_discriminant,
        },
        "frequency": {
          "numerator": frequency_numerator,
          "denominator": 15,
        },
      },
    },
  }
  validate_agent_snapshot(snapshot)
  return snapshot


def validate_agent_snapshot(snapshot: Dict[str, Any]) -> None:
  if not isinstance(snapshot, dict):
    raise AgentLifecycleError("snapshot must be object")
  _require_exact_keys(snapshot, ("v", "authority", "observer", "identity", "channels"), "snapshot")
  if snapshot["v"] != SNAPSHOT_SCHEMA_V:
    raise AgentLifecycleError("snapshot schema mismatch")
  if snapshot["authority"] != "advisory":
    raise AgentLifecycleError("snapshot authority must be advisory")
  if not isinstance(snapshot["observer"], str) or not snapshot["observer"]:
    raise AgentLifecycleError("observer must be non-empty string")

  ident = snapshot["identity"]
  if not isinstance(ident, dict):
    raise AgentLifecycleError("identity must be object")
  _require_exact_keys(ident, ("sid", "point", "line", "pua_codepoint"), "identity")
  _sid_hex(ident["sid"])
  if not isinstance(ident["point"], int) or not (1 <= ident["point"] <= 60):
    raise AgentLifecycleError("point must be in 1..60")
  if not isinstance(ident["line"], int) or not (1 <= ident["line"] <= 15):
    raise AgentLifecycleError("line must be in 1..15")
  if not isinstance(ident["pua_codepoint"], str) or not ident["pua_codepoint"].startswith("U+"):
    raise AgentLifecycleError("pua_codepoint must be U+*")

  channels = snapshot["channels"]
  if not isinstance(channels, dict):
    raise AgentLifecycleError("channels must be object")
  _require_exact_keys(channels, ("binary", "decimal", "hex", "sign"), "channels")

  binary = channels["binary"]
  _require_exact_keys(binary, ("source_sha256", "normal_form_sha256"), "channels.binary")
  _sid_hex(binary["source_sha256"])
  _sid_hex(binary["normal_form_sha256"])

  decimal = channels["decimal"]
  _require_exact_keys(decimal, ("sid", "sid_u64_mod"), "channels.decimal")
  if decimal["sid"] != ident["sid"]:
    raise AgentLifecycleError("decimal.sid mismatch with identity.sid")
  if not isinstance(decimal["sid_u64_mod"], int) or decimal["sid_u64_mod"] < 0:
    raise AgentLifecycleError("sid_u64_mod must be non-negative integer")

  hex_ch = channels["hex"]
  _require_exact_keys(hex_ch, ("module", "language", "point", "line", "coords_digest"), "channels.hex")
  if hex_ch["language"] not in SUPPORTED_LANGUAGES:
    raise AgentLifecycleError("channels.hex.language unsupported")
  if not isinstance(hex_ch["module"], str) or not hex_ch["module"]:
    raise AgentLifecycleError("channels.hex.module must be non-empty string")
  if hex_ch["point"] != ident["point"] or hex_ch["line"] != ident["line"]:
    raise AgentLifecycleError("channels.hex point/line mismatch with identity")
  _sid_hex(hex_ch["coords_digest"])

  sign = channels["sign"]
  _require_exact_keys(sign, ("p_adic", "frame", "frequency"), "channels.sign")

  p_adic = sign["p_adic"]
  _require_exact_keys(p_adic, ("prime", "value", "valuation", "trail"), "channels.sign.p_adic")
  if p_adic["prime"] not in PADIC_PRIMES:
    raise AgentLifecycleError("p_adic prime unsupported")
  if not isinstance(p_adic["value"], int):
    raise AgentLifecycleError("p_adic value must be integer")
  if not isinstance(p_adic["valuation"], int) or p_adic["valuation"] < 0:
    raise AgentLifecycleError("p_adic valuation must be non-negative integer")
  if not isinstance(p_adic["trail"], list) or len(p_adic["trail"]) != 8:
    raise AgentLifecycleError("p_adic trail must be list of 8 digits")

  frame = sign["frame"]
  _require_exact_keys(frame, ("step", "discriminant"), "channels.sign.frame")
  if not isinstance(frame["step"], int) or frame["step"] < 0:
    raise AgentLifecycleError("frame.step must be integer >= 0")
  if not isinstance(frame["discriminant"], int):
    raise AgentLifecycleError("frame.discriminant must be integer")

  frequency = sign["frequency"]
  _require_exact_keys(frequency, ("numerator", "denominator"), "channels.sign.frequency")
  if not isinstance(frequency["numerator"], int) or not (0 <= frequency["numerator"] < 15):
    raise AgentLifecycleError("frequency.numerator must be integer in [0, 14]")
  if frequency["denominator"] != 15:
    raise AgentLifecycleError("frequency.denominator must be 15")


def compare_agent_snapshots(previous: Dict[str, Any], current: Dict[str, Any]) -> Dict[str, Any]:
  validate_agent_snapshot(previous)
  validate_agent_snapshot(current)

  prev_id = previous["identity"]
  cur_id = current["identity"]
  same_sid = prev_id["sid"] == cur_id["sid"]
  same_geometry = (prev_id["point"], prev_id["line"]) == (cur_id["point"], cur_id["line"])

  if same_sid and same_geometry:
    state = "unchanged"
  elif (not same_sid) and same_geometry:
    state = "evolved_preserving_geometry"
  else:
    state = "reborn"

  return {
    "v": "tetragrammatron.agent_lifecycle.compare.v0",
    "authority": "advisory",
    "same_sid": same_sid,
    "same_geometry": same_geometry,
    "state": state,
  }
