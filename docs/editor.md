# Editor Tools

Editor integration for world editing and intent capture.

## Tools

### Intent to Event

```bash
python3 editor/intent-to-event.py
```

Converts user intent to lifecycle events.

### World Edit

```bash
bash editor/world-edit.sh
```

Direct world editing interface.

## Tests

```bash
bash editor/editor-tests.sh
```

## Contract

Editor tools are projections. They must:
1. Pass through AuthorityGate for any world modification
2. Emit trace events for all actions
3. Be downstream of the kernel
4. Never write truth directly
