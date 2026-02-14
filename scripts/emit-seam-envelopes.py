#!/usr/bin/env python3
"""
metaverse-build -> ULP seam envelope emitter (Producer).

This adapter locks the seam contract for "build facts" without running a build:
- Input: a small JSON build report.
- Output: port-matroid seam envelopes (NDJSON).
- All values are strings, stable ordering, fail-closed structure.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


def canonical_json(obj: object) -> str:
    return json.dumps(obj, sort_keys=True, separators=(",", ":"), ensure_ascii=True)


def sha256_hex(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def emit_ndjson(obj: dict) -> None:
    print(json.dumps(obj, sort_keys=True, separators=(",", ":"), ensure_ascii=True))

def component_prefix(namespace: str) -> str:
    parts = namespace.split(".")
    if len(parts) < 4 or parts[0:2] != ["ulp", "trace"]:
        raise SystemExit(f"namespace invalid (expected ulp.trace.<producer>.*.vN): {namespace!r}")
    return parts[2] + "__"


def main() -> int:
    ap = argparse.ArgumentParser(description="Emit ULP seam envelopes for metaverse-build fixtures.")
    ap.add_argument("--input", required=True, help="Path to build report JSON")
    ap.add_argument("--namespace", default="ulp.trace.metaverse_build.v0")
    ap.add_argument("--writer", default="metaverse-build")
    ap.add_argument("--epoch", type=int, default=1)
    ap.add_argument("--gen", type=int, default=1)
    ap.add_argument("--owner-mask", type=int, default=15)
    args = ap.parse_args()
    prefix = component_prefix(args.namespace)

    in_path = Path(args.input)
    root = json.loads(in_path.read_text())

    if set(root.keys()) != {"build", "artifacts"}:
        raise SystemExit("input JSON must have exact keys: build, artifacts")
    build = root["build"]
    artifacts = root["artifacts"]

    if not isinstance(build, dict) or not isinstance(artifacts, list):
        raise SystemExit("build must be object; artifacts must be array")

    # Normalize artifacts ordering so input digests are invariant to list ordering.
    # This is the "numeric membrane" equivalent for build facts: order doesn't carry authority.
    artifacts_norm = sorted(artifacts, key=lambda a: str(a.get("name", "")))
    normalized_root = {"build": build, "artifacts": artifacts_norm}

    # Input digest must be invariant to JSON key ordering and artifact list ordering.
    # Do not bind replay identity to filenames.
    input_digest = "sha256:" + sha256_hex(canonical_json(normalized_root).encode("utf-8"))

    # Fail-closed required build keys.
    if set(build.keys()) != {"exit", "plan_text", "profile", "toolchain"}:
        raise SystemExit("build must have exact keys: exit, plan_text, profile, toolchain")
    toolchain = build["toolchain"]
    if not isinstance(toolchain, dict) or set(toolchain.keys()) != {"ghc", "node", "python"}:
        raise SystemExit("toolchain must have exact keys: ghc, node, python")

    authority = {"kind": "direct", "basis": []}
    meta = {"writer": args.writer, "epoch": args.epoch, "gen": args.gen}

    def env(payload: dict) -> dict:
        return {"namespace": args.namespace, "authority": authority, "meta": meta, "payload": payload}

    # Digests: bind the intent and outputs.
    plan_digest = "sha256:" + sha256_hex(str(build["plan_text"]).encode("utf-8"))
    toolchain_digest = "sha256:" + sha256_hex(canonical_json(toolchain).encode("utf-8"))
    artifacts_sorted = artifacts_norm

    artifact_digests: list[str] = []
    artifact_rows: list[tuple[str, str, str]] = []  # (name, digest, size_str)

    for a in artifacts_sorted:
        if not isinstance(a, dict) or set(a.keys()) != {"name", "mime", "content_utf8"}:
            raise SystemExit("each artifact must have exact keys: name, mime, content_utf8")
        name = str(a["name"])
        mime = str(a["mime"])
        content = str(a["content_utf8"]).encode("utf-8")
        digest = "sha256:" + sha256_hex(content)
        size = str(len(content))
        artifact_digests.append(f"{name}:{digest}:{size}:{mime}\n")
        artifact_rows.append((name, digest, size))

    artifacts_digest = "sha256:" + sha256_hex(("".join(artifact_digests)).encode("utf-8"))
    build_digest = "sha256:" + sha256_hex((plan_digest + "\n" + toolchain_digest + "\n" + artifacts_digest + "\n").encode("utf-8"))

    # Entities:
    # - trace root (eid=1)
    # - build entity (eid=2)
    # - artifact entities (eid=100+idx)
    trace_eid = 1
    build_eid = 2

    emit_ndjson(env({"op": "create_entity", "eid": trace_eid, "etype": "trace", "owner_mask": args.owner_mask}))
    emit_ndjson(env({"op": "set_component_string", "eid": trace_eid, "key": prefix + "trace_kind", "value": "build_report_fixture"}))
    emit_ndjson(env({"op": "set_component_string", "eid": trace_eid, "key": prefix + "trace_source", "value": "build_report"}))
    emit_ndjson(env({"op": "set_component_string", "eid": trace_eid, "key": prefix + "trace_input_digest", "value": input_digest}))
    emit_ndjson(env({"op": "set_component_string", "eid": trace_eid, "key": prefix + "trace_build_digest", "value": build_digest}))

    emit_ndjson(env({"op": "create_entity", "eid": build_eid, "etype": "build", "owner_mask": args.owner_mask}))
    emit_ndjson(env({"op": "set_component_string", "eid": build_eid, "key": prefix + "build_digest", "value": build_digest}))
    emit_ndjson(env({"op": "set_component_string", "eid": build_eid, "key": prefix + "build_exit", "value": str(build["exit"])}))
    emit_ndjson(env({"op": "set_component_string", "eid": build_eid, "key": prefix + "build_profile", "value": str(build["profile"])}))
    emit_ndjson(env({"op": "set_component_string", "eid": build_eid, "key": prefix + "build_plan_digest", "value": plan_digest}))
    emit_ndjson(env({"op": "set_component_string", "eid": build_eid, "key": prefix + "toolchain_digest", "value": toolchain_digest}))
    emit_ndjson(env({"op": "set_component_string", "eid": build_eid, "key": prefix + "artifacts_digest", "value": artifacts_digest}))
    emit_ndjson(env({"op": "set_component_string", "eid": build_eid, "key": prefix + "artifact_count", "value": str(len(artifact_rows))}))

    # Include toolchain fingerprint facts as strings (governance-visible).
    emit_ndjson(env({"op": "set_component_string", "eid": build_eid, "key": prefix + "toolchain_node", "value": str(toolchain["node"])}))
    emit_ndjson(env({"op": "set_component_string", "eid": build_eid, "key": prefix + "toolchain_python", "value": str(toolchain["python"])}))
    emit_ndjson(env({"op": "set_component_string", "eid": build_eid, "key": prefix + "toolchain_ghc", "value": str(toolchain["ghc"])}))

    for idx, (name, digest, size) in enumerate(artifact_rows):
        eid = 100 + idx
        emit_ndjson(env({"op": "create_entity", "eid": eid, "etype": "artifact", "owner_mask": args.owner_mask}))
        emit_ndjson(env({"op": "set_component_string", "eid": eid, "key": prefix + "artifact_name", "value": name}))
        emit_ndjson(env({"op": "set_component_string", "eid": eid, "key": prefix + "artifact_digest", "value": digest}))
        emit_ndjson(env({"op": "set_component_string", "eid": eid, "key": prefix + "artifact_size_bytes", "value": size}))
        emit_ndjson(env({"op": "set_component_string", "eid": eid, "key": prefix + "artifact_build_digest", "value": build_digest}))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
