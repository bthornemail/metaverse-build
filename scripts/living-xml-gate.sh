#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PYTHONPATH="$ROOT:${PYTHONPATH:-}"
ACCEPT_DIR="$ROOT/runtime/tetragrammatron/fixtures/living-xml/accept"
MR_DIR="$ROOT/runtime/tetragrammatron/fixtures/living-xml/must-reject"
MR_EXPECT="$MR_DIR/expectations.json"
SCHEMA="$ROOT/runtime/tetragrammatron/schemas/living-xml.rng"
SCHEMA_VALIDATOR="$ROOT/runtime/tetragrammatron/tools/validate_living_xml_rng.py"
FUZZ_TOOL="$ROOT/runtime/tetragrammatron/tools/living_xml_fuzz.py"
REPORT="$ROOT/reports/phase27H-living-xml.json"
HARDENING_REPORT="$ROOT/reports/phase27H-living-xml-hardening.json"
GOLDEN_HASH="$ROOT/golden/living-xml/replay-hash"
HARDENING_HASH="$ROOT/golden/living-xml/hardening-replay-hash"
TMP_REPORT="$(mktemp)"
TMP_HARDENING="$(mktemp)"
TMP_SMALL="$(mktemp)"
TMP_MEDIUM="$(mktemp)"
TMP_EXTENDED="$(mktemp)"
trap 'rm -f "$TMP_REPORT" "$TMP_HARDENING" "$TMP_SMALL" "$TMP_MEDIUM" "$TMP_EXTENDED"' EXIT

SMALL_SEED="${LIVING_XML_FUZZ_SMALL_SEED:-27100}"
MEDIUM_SEED="${LIVING_XML_FUZZ_MEDIUM_SEED:-27200}"
EXTENDED_SEED="${LIVING_XML_FUZZ_EXTENDED_SEED:-27300}"
SMALL_COUNT="${LIVING_XML_FUZZ_SMALL_COUNT:-100}"
MEDIUM_COUNT="${LIVING_XML_FUZZ_MEDIUM_COUNT:-1000}"
EXTENDED_COUNT="${LIVING_XML_FUZZ_EXTENDED_COUNT:-5000}"
RUN_EXTENDED="${LIVING_XML_FUZZ_EXTENDED:-0}"

if [[ ! -d "$ACCEPT_DIR" ]]; then
  echo "missing accept fixture directory: $ACCEPT_DIR" >&2
  exit 2
fi
if [[ ! -d "$MR_DIR" ]]; then
  echo "missing must-reject fixture directory: $MR_DIR" >&2
  exit 2
fi
for required in "$MR_EXPECT" "$SCHEMA" "$SCHEMA_VALIDATOR" "$FUZZ_TOOL" "$GOLDEN_HASH" "$HARDENING_HASH"; do
  if [[ ! -f "$required" ]]; then
    echo "missing required file: $required" >&2
    exit 2
  fi
done

mkdir -p "$(dirname "$REPORT")" "$(dirname "$HARDENING_REPORT")"

schema_validate_accept() {
  local xml="$1"
  if command -v jing >/dev/null 2>&1; then
    jing "$SCHEMA" "$xml" >/dev/null
  elif [[ -n "${JING_JAR:-}" && -f "${JING_JAR:-}" ]]; then
    java -jar "$JING_JAR" "$SCHEMA" "$xml" >/dev/null
  else
    python3 "$SCHEMA_VALIDATOR" "$SCHEMA" "$xml" >/dev/null
  fi
}

# 1) Accept fixtures: schema + runtime validation.
for accept_xml in "$ACCEPT_DIR"/*.xml; do
  [[ -f "$accept_xml" ]] || continue
  schema_validate_accept "$accept_xml"
  python3 - <<PY >/dev/null
from runtime.tetragrammatron.io.living_xml import parse_living_xml
xml = open(r"$accept_xml", "r", encoding="utf-8").read()
parse_living_xml(xml)
PY
done

# 2) Must-reject: local schema validator must fail + runtime class must match expectation.
python3 - <<PY >/dev/null
import json
from pathlib import Path
from runtime.tetragrammatron.io.living_xml import LivingXmlError, parse_living_xml
from runtime.tetragrammatron.tools.validate_living_xml_rng import SchemaValidationError, validate as validate_rng

mr_dir = Path(r"$MR_DIR")
expect = json.loads(Path(r"$MR_EXPECT").read_text(encoding="utf-8"))
schema = r"$SCHEMA"

def classify(text: str) -> str:
  t = text.lower()
  if "attrs mismatch" in t or " attr" in t:
    return "attr"
  if "invalid xml" in t or "parse" in t:
    return "xml"
  if "tick" in t:
    return "tick"
  if "code" in t:
    return "code"
  if "nested" in t or "terminal" in t or "tail" in t or "text" in t:
    return "terminal"
  return "structure"

for path in sorted(mr_dir.glob("*.xml")):
  name = path.name
  if name not in expect:
    raise SystemExit(f"missing expected class mapping for {name}")
  xml = path.read_text(encoding="utf-8")
  try:
    validate_rng(schema, str(path))
    raise SystemExit(f"must-reject schema accepted invalid xml: {name}")
  except SchemaValidationError:
    pass
  try:
    parse_living_xml(xml)
    raise SystemExit(f"must-reject runtime accepted invalid xml: {name}")
  except LivingXmlError as exc:
    got = classify(str(exc))
    want = expect[name]
    if got != want:
      raise SystemExit(f"must-reject class mismatch for {name}: expected {want} got {got} ({exc})")
PY

# 3) Deterministic tiered fuzz (small + medium default; extended optional).
python3 "$FUZZ_TOOL" --schema "$SCHEMA" --tier small --seed "$SMALL_SEED" --count "$SMALL_COUNT" > "$TMP_SMALL"
python3 "$FUZZ_TOOL" --schema "$SCHEMA" --tier medium --seed "$MEDIUM_SEED" --count "$MEDIUM_COUNT" > "$TMP_MEDIUM"
if [[ "$RUN_EXTENDED" == "1" ]]; then
  python3 "$FUZZ_TOOL" --schema "$SCHEMA" --tier extended --seed "$EXTENDED_SEED" --count "$EXTENDED_COUNT" > "$TMP_EXTENDED"
else
  printf '{"tier":"extended","skipped":true,"seed":%s,"count":%s}\n' "$EXTENDED_SEED" "$EXTENDED_COUNT" > "$TMP_EXTENDED"
fi

# 4) Canonical report + hardening report.
python3 - <<PY > "$TMP_REPORT"
import json
from pathlib import Path
from runtime.tetragrammatron.io.living_xml import parse_living_xml, circulation_trace, advance_living_xml

accept_dir = Path(r"$ACCEPT_DIR")
cases = []
for path in sorted(accept_dir.glob("*.xml")):
  xml = path.read_text(encoding="utf-8")
  parsed = parse_living_xml(xml)
  cases.append(
    {
      "name": path.name,
      "parsed": parsed["fs"],
      "tick": parsed["tick"],
      "trace": circulation_trace(xml, 8),
      "advanced_xml": advance_living_xml(xml),
    }
  )
report = {
  "v": "phase27H.living_xml.v0",
  "authority": "advisory",
  "cases": cases,
}
print(json.dumps(report, sort_keys=True, separators=(",", ":"), ensure_ascii=False))
PY

python3 - <<PY > "$TMP_HARDENING"
import json
from pathlib import Path

accept_files = [p.name for p in sorted(Path(r"$ACCEPT_DIR").glob("*.xml"))]
mr_files = [p.name for p in sorted(Path(r"$MR_DIR").glob("*.xml"))]
expect_map = json.loads(Path(r"$MR_EXPECT").read_text(encoding="utf-8"))
small = json.loads(Path(r"$TMP_SMALL").read_text(encoding="utf-8"))
medium = json.loads(Path(r"$TMP_MEDIUM").read_text(encoding="utf-8"))
extended = json.loads(Path(r"$TMP_EXTENDED").read_text(encoding="utf-8"))

report = {
  "v": "phase27H.living_xml_hardening.v0",
  "authority": "advisory",
  "schema_path": "runtime/tetragrammatron/schemas/living-xml.rng",
  "accept_fixture_count": len(accept_files),
  "accept_fixtures": accept_files,
  "must_reject_fixture_count": len(mr_files),
  "must_reject_fixtures": mr_files,
  "must_reject_expected_classes": expect_map,
  "fuzz": {
    "small": small,
    "medium": medium,
    "extended": extended,
  },
}
print(json.dumps(report, sort_keys=True, separators=(",", ":"), ensure_ascii=False))
PY

cp "$TMP_REPORT" "$REPORT"
cp "$TMP_HARDENING" "$HARDENING_REPORT"

# 5) Hash locks.
want="$(tr -d '\n' < "$GOLDEN_HASH")"
got="sha256:$(sha256sum "$TMP_REPORT" | awk '{print $1}')"
if [[ "$want" != "$got" ]]; then
  echo "living-xml replay hash mismatch: expected $want got $got" >&2
  sed -n '1,160p' "$TMP_REPORT" >&2
  exit 1
fi

want_h="$(tr -d '\n' < "$HARDENING_HASH")"
got_h="sha256:$(sha256sum "$TMP_HARDENING" | awk '{print $1}')"
if [[ "$want_h" != "$got_h" ]]; then
  echo "living-xml hardening hash mismatch: expected $want_h got $got_h" >&2
  sed -n '1,160p' "$TMP_HARDENING" >&2
  exit 1
fi

echo "ok living-xml gate"
