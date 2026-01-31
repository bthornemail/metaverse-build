# Failure Modes

| Failure | Halt Location | Exit | Output |
|---|---|---|---|
| InvalidSchemaPrefix | AuthorityGate | non-zero | HALT, no projection |
| UnknownAuthority | AuthorityGate | non-zero | HALT, no projection |
| CrossDomainEscalation | AuthorityGate | non-zero | HALT, no projection |
| HALT: no publish | MQTT publish wrapper | non-zero | no broker publish |
