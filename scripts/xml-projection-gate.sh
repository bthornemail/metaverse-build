#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACCEPT_DIR="$ROOT/runtime/tetragrammatron/fixtures/xml-projection/accept"
GOLDEN_DIR="$ROOT/golden/xml-projection"
MR_DIR="$ROOT/runtime/tetragrammatron/fixtures/xml-projection/must-reject"
REPORT_DIR="$ROOT/reports"
PROJECTIVE_REPORT="$REPORT_DIR/phase27D-projective-time.json"
PROJECTIVE_GOLDEN_HASH="$GOLDEN_DIR/projective-time.replay-hash"

TMP_XML="$(mktemp)"
trap 'rm -f "$TMP_XML"' EXIT

for accept_json in "$ACCEPT_DIR"/*.json; do
  if [[ ! -f "$accept_json" ]]; then
    continue
  fi
  base="$(basename "$accept_json" .json)"
  golden_xml="$GOLDEN_DIR/$base.xml"
  if [[ ! -f "$golden_xml" ]]; then
    echo "missing golden xml: $golden_xml" >&2
    exit 2
  fi

  python3 - <<PY > "$TMP_XML"
import json
from runtime.tetragrammatron.io.xml_projection import world_to_xml
with open(r"$accept_json", "r", encoding="utf-8") as f:
  world = json.load(f)
print(world_to_xml(world), end="")
PY

  if ! cmp -s "$TMP_XML" "$golden_xml"; then
    echo "xml projection golden mismatch for $base" >&2
    echo "--- generated ---" >&2
    sed -n '1,120p' "$TMP_XML" >&2
    echo "--- expected ---" >&2
    sed -n '1,120p' "$golden_xml" >&2
    exit 1
  fi

  python3 - <<PY
import json
from runtime.tetragrammatron.io.xml_projection import world_to_xml, xml_to_world
with open(r"$accept_json", "r", encoding="utf-8") as f:
  world = json.load(f)
roundtrip = xml_to_world(world_to_xml(world))
if roundtrip != world:
  raise SystemExit("xml roundtrip mismatch for $base")
PY
done

mkdir -p "$REPORT_DIR"
python3 - <<PY
import glob
import json
import os
from runtime.tetragrammatron.io.xml_projection import world_to_xml
from runtime.tetragrammatron.io.projective_time import xml_time_signature
from runtime.tetragrammatron.io.p_adic_time import signature_to_clock

accept = sorted(glob.glob(os.path.join(r"$ACCEPT_DIR", "*.json")))
rows = []
for path in accept:
  with open(path, "r", encoding="utf-8") as f:
    world = json.load(f)
  xml = world_to_xml(world)
  sig = xml_time_signature(xml)
  clock = signature_to_clock(sig, primes=(2, 3, 5, 7), trail_len=8)
  rows.append({
    "fixture": os.path.basename(path),
    "projective": {
      "a": sig.a,
      "b": sig.b,
      "c": sig.c,
      "discriminant": sig.discriminant,
      "class": sig.class_name,
      "step_length": sig.step_length,
      "genus": sig.genus,
      "element_count": sig.element_count,
      "control_count": sig.control_count,
      "unit_count": sig.unit_count,
      "payload_char_count": sig.payload_char_count,
    },
    "p_adic": {
      "value": clock.value,
      "primes": list(clock.primes),
      "trail_len": clock.trail_len,
      "valuations": {str(k): v for k, v in clock.valuations.items()},
      "trails": {str(k): list(v) for k, v in clock.trails.items()},
    },
  })

payload = {
  "v": "phase27D.projective_time.v0",
  "authority": "advisory",
  "fixtures": rows,
}

with open(r"$PROJECTIVE_REPORT", "w", encoding="utf-8") as f:
  f.write(json.dumps(payload, sort_keys=True, separators=(",", ":"), ensure_ascii=False))
  f.write("\n")
PY

if [[ ! -f "$PROJECTIVE_GOLDEN_HASH" ]]; then
  echo "missing projective-time golden hash: $PROJECTIVE_GOLDEN_HASH" >&2
  exit 2
fi
want_report_hash="$(tr -d '\n' < "$PROJECTIVE_GOLDEN_HASH")"
got_report_hash="sha256:$(sha256sum "$PROJECTIVE_REPORT" | awk '{print $1}')"
if [[ "$want_report_hash" != "$got_report_hash" ]]; then
  echo "projective-time report hash mismatch: expected $want_report_hash got $got_report_hash" >&2
  sed -n '1,120p' "$PROJECTIVE_REPORT" >&2
  exit 1
fi

for bad in "$MR_DIR"/*.xml; do
  if [[ ! -f "$bad" ]]; then
    continue
  fi
  set +e
  err="$(python3 - <<PY 2>&1 >/dev/null
from runtime.tetragrammatron.io.xml_projection import xml_to_world
with open(r"$bad", "r", encoding="utf-8") as f:
  xml_to_world(f.read())
print("accepted invalid xml")
raise SystemExit(1)
PY
)"
  status=$?
  set -e
  if [[ $status -eq 0 ]]; then
    echo "must-reject accepted invalid xml: $bad" >&2
    exit 1
  fi
  if ! printf '%s' "$err" | grep -Eq 'ValueError|mismatch|must contain|unknown|duplicate'; then
    echo "must-reject unexpected error for $bad: $err" >&2
    exit 1
  fi
done

for bad_json in "$MR_DIR"/*.json; do
  if [[ ! -f "$bad_json" ]]; then
    continue
  fi
  set +e
  err="$(python3 - <<PY 2>&1 >/dev/null
import json
from runtime.tetragrammatron.io.xml_projection import world_to_xml
with open(r"$bad_json", "r", encoding="utf-8") as f:
  world = json.load(f)
world_to_xml(world)
print("accepted invalid world json")
raise SystemExit(1)
PY
)"
  status=$?
  set -e
  if [[ $status -eq 0 ]]; then
    echo "must-reject accepted invalid world json: $bad_json" >&2
    exit 1
  fi
  if ! printf '%s' "$err" | grep -Eq 'ValueError|schema mismatch|must be object'; then
    echo "must-reject unexpected world-json error for $bad_json: $err" >&2
    exit 1
  fi
done

echo "ok xml projection gate"
