#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE_DIR="$ROOT/runtime/tetragrammatron/fixtures/light-garden-sphere/accept"
REPORT="$ROOT/reports/phase27E-light-garden-sphere.json"
GOLDEN_HASH_FILE="$ROOT/golden/light-garden-sphere/replay-hash"

if [[ ! -d "$FIXTURE_DIR" ]]; then
  echo "missing fixture directory: $FIXTURE_DIR" >&2
  exit 2
fi
if [[ ! -f "$GOLDEN_HASH_FILE" ]]; then
  echo "missing golden hash file: $GOLDEN_HASH_FILE" >&2
  exit 2
fi

mkdir -p "$(dirname "$REPORT")"

python3 - <<PY
import glob
import json
from runtime.tetragrammatron.io.light_garden_sphere import encode_frame, encode_sphere, decode_frame

fixture_dir = r"$FIXTURE_DIR"
report_path = r"$REPORT"

paths = sorted(glob.glob(f"{fixture_dir}/*.json"))
if not paths:
  raise SystemExit("no light-garden fixtures found")

rows = []
for fixture_path in paths:
  with open(fixture_path, "r", encoding="utf-8") as f:
    fixture = json.load(f)

  if set(fixture.keys()) != {"v", "authority", "points"}:
    raise SystemExit(f"fixture keyset mismatch: {fixture_path}")
  if fixture["v"] != "tetragrammatron.light_garden_sphere.fixture.v0":
    raise SystemExit(f"fixture schema mismatch: {fixture_path}")
  if fixture["authority"] != "advisory":
    raise SystemExit(f"fixture authority mismatch: {fixture_path}")

  points = fixture["points"]
  bundle = encode_sphere(points)

  # Fail-closed deterministic checks on representative frames.
  for fid in (0, 1, 59, 120, 239):
    frame = encode_frame(points, fid)
    roundtrip = decode_frame(frame)
    if roundtrip != points:
      raise SystemExit(f"roundtrip mismatch at frame {fid}: {fixture_path}")

  centroids = [bundle["frames"][i]["centroid"] for i in (0, 137, 239)]
  if not (centroids[0] == centroids[1] == centroids[2]):
    raise SystemExit(f"centroid invariant mismatch: {fixture_path}")

  rows.append({
    "fixture": fixture_path.split("/")[-1],
    "bundle": bundle,
  })

payload = {
  "v": "phase27E.light_garden_sphere.v0",
  "authority": "advisory",
  "fixtures": rows,
}

with open(report_path, "w", encoding="utf-8") as f:
  f.write(json.dumps(payload, sort_keys=True, separators=(",", ":"), ensure_ascii=False))
  f.write("\n")
PY

want="$(tr -d '\n' < "$GOLDEN_HASH_FILE")"
got="sha256:$(sha256sum "$REPORT" | awk '{print $1}')"
if [[ "$want" != "$got" ]]; then
  echo "light-garden-sphere replay hash mismatch: expected $want got $got" >&2
  sed -n '1,80p' "$REPORT" >&2
  exit 1
fi

echo "ok light-garden-sphere gate"
