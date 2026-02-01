# Zone Authority Delegation (Phase 32C)

Zone authority defines which actors may emit lifecycle events targeting a zone.

This is an additional guardrail on top of entity ownership.

---

## Policy Shape

```json
{
  "zone-a": ["valid:userA"],
  "zone-b": ["valid:userB"],
  "*": ["valid:admin"]
}
```

- Zone-specific lists are allowed actors.
- `*` is a global allow list.

---

## Rule

An event targeting a zone is allowed if:

- actor is in `policy[zone]`, or
- actor is in `policy[*]`

Otherwise, HALT with `ZoneNotAuthorized`.

---

## Scope

- Zone authority does not change entity ownership.
- Ownership checks still apply.

This phase does not add delegation or transfer.
