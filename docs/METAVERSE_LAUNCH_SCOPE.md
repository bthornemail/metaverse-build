# Metaverse Launch Scope
Status: Advisory
Authority: Advisory
Depends on: `reports/production-readiness/metaverse-readiness.json`, `scripts/tetragrammatron-gate.sh`, `scripts/check-ops-rollback-restore-drill.sh`, `scripts/closure-spine-smoke.sh`

## In Scope (Production-Bounded)
- Deterministic canonical runtime path is production-approved on the validated gate chain.
- Tetragrammatron/control-plane derived runtime gates:
  - tetragrammatron
  - ast-spherepack
  - living-xml
  - identity
  - seed-algebra
  - lane16
- Browser/projector path as projection-only surface with no-authority enforcement.
- Runtime handoff/materialize contracts (Wave30/Wave31) and release verification.
- Closure-spine and rollback/restore operational drills currently green.

## Out of Scope (This Launch)
- Claims of fully validated cross-browser engine matrix beyond current validated CI/projector contract checks.
- Any draft/experimental extension that is not covered by current release-critical gates.
- Any workflow that mutates canonical truth from UI/projection surfaces.

## Authority Posture
- Canonical truth remains deterministic and validator-enforced.
- Projection/browser surfaces remain advisory-only.
- Atomic Kernel vNext lane is promoted normative by policy; compatibility window remains active.

## Rollback Conditions
Treat as rollback-condition triggers if any occurs:
- parity regression (replay/API/Coq),
- authority-boundary regression,
- release/closure spine failure,
- deterministic canonical artifact drift without approved semantic/version change.
