#!/usr/bin/env python3
import json
import os
import sys


def fail(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)


def require_obj(x, label):
    if not isinstance(x, dict):
        fail(f"{label} must be object")


def require_str(x, label):
    if not isinstance(x, str):
        fail(f"{label} must be string")


def require_array(x, label):
    if not isinstance(x, list):
        fail(f"{label} must be array")


def assert_keyset(obj, keys, label):
    got = sorted(obj.keys())
    want = sorted(keys)
    if got != want:
        fail(f"{label} keyset mismatch")


def validate_entity(obj, i):
    require_obj(obj, f"entity[{i}]")
    for k in obj.keys():
        if k not in ("id", "components", "owner", "zone"):
            fail(f"entity[{i}] unknown key: {k}")
    if "id" not in obj or "components" not in obj:
        fail(f"entity[{i}] missing required keys")
    require_str(obj["id"], f"entity[{i}].id")
    require_array(obj["components"], f"entity[{i}].components")
    if "owner" in obj:
        require_str(obj["owner"], f"entity[{i}].owner")
    if "zone" in obj:
        require_str(obj["zone"], f"entity[{i}].zone")
    for j, c in enumerate(obj["components"]):
        require_obj(c, f"entity[{i}].components[{j}]")
        if "type" not in c:
            fail(f"entity[{i}].components[{j}] missing type")
        require_str(c["type"], f"entity[{i}].components[{j}].type")
        if "data" in c and not isinstance(c["data"], dict):
            fail(f"entity[{i}].components[{j}].data must be object")


def validate_zone(obj, i):
    require_obj(obj, f"zone[{i}]")
    for k in obj.keys():
        if k not in ("id", "bounds", "tags"):
            fail(f"zone[{i}] unknown key: {k}")
    if "id" not in obj:
        fail(f"zone[{i}] missing id")
    require_str(obj["id"], f"zone[{i}].id")
    if "bounds" in obj and not isinstance(obj["bounds"], dict):
        fail(f"zone[{i}].bounds must be object")
    if "tags" in obj:
        require_array(obj["tags"], f"zone[{i}].tags")
        for j, tag in enumerate(obj["tags"]):
            require_str(tag, f"zone[{i}].tags[{j}]")


def validate_rule(obj, i):
    require_obj(obj, f"rule[{i}]")
    assert_keyset(obj, ["id", "guard", "effect"], f"rule[{i}]")
    require_str(obj["id"], f"rule[{i}].id")
    require_obj(obj["guard"], f"rule[{i}].guard")
    require_obj(obj["effect"], f"rule[{i}].effect")


def validate_portal(obj, i):
    require_obj(obj, f"portal[{i}]")
    assert_keyset(obj, ["id", "entry"], f"portal[{i}]")
    require_str(obj["id"], f"portal[{i}].id")
    require_obj(obj["entry"], f"portal[{i}].entry")


def validate_attachment(obj, i):
    require_obj(obj, f"attachment[{i}]")
    for k in obj.keys():
        if k not in ("id", "target", "kind", "ref"):
            fail(f"attachment[{i}] unknown key: {k}")
    for k in ("id", "target", "kind"):
        if k not in obj:
            fail(f"attachment[{i}] missing {k}")
        require_str(obj[k], f"attachment[{i}].{k}")
    if "ref" in obj:
        require_str(obj["ref"], f"attachment[{i}].ref")


def validate_event(obj, i):
    require_obj(obj, f"event[{i}]")
    for k in obj.keys():
        if k not in ("id", "intent", "authority"):
            fail(f"event[{i}] unknown key: {k}")
    if "id" not in obj or "intent" not in obj:
        fail(f"event[{i}] missing required keys")
    require_str(obj["id"], f"event[{i}].id")
    require_obj(obj["intent"], f"event[{i}].intent")
    if "authority" in obj:
        require_str(obj["authority"], f"event[{i}].authority")


def main():
    if len(sys.argv) != 2:
        fail("usage: validate-ir.py <world.ir.json>")

    p = sys.argv[1]
    if not os.path.exists(p):
        fail(f"input not found: {p}")

    with open(p, "r") as fh:
        data = json.load(fh)

    require_obj(data, "world.ir")
    for k in data.keys():
        if k not in ("world", "entities", "zones", "rules", "portals", "attachments", "events"):
            fail(f"world.ir unknown key: {k}")
    if "world" not in data:
        fail("world.ir missing world")
    require_str(data["world"], "world.ir.world")

    for arr_name, item_validator in (
        ("entities", validate_entity),
        ("zones", validate_zone),
        ("rules", validate_rule),
        ("portals", validate_portal),
        ("attachments", validate_attachment),
        ("events", validate_event),
    ):
        if arr_name in data:
            require_array(data[arr_name], f"world.ir.{arr_name}")
            for i, obj in enumerate(data[arr_name]):
                item_validator(obj, i)

    print("ok world-ir schema validation")


if __name__ == "__main__":
    main()
