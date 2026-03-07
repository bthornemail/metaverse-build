# Layer Contract: metaverse-build Runtime Host

This contract defines metaverse-build as the non-authoritative execution host.

## Component

- Name: `metaverse-build runtime host`
- Repository path: `/home/main/devops/metaverse-build`
- Owner: runtime maintainers
- Status: active

## Layer Declaration

- Layer: hypervisor
- Why this layer: this repo realizes authority-gated execution flow and runtime orchestration without redefining protocol law.

## Authority Class

- Authority class: advisory
- Authority boundary statement:
  - What this component is allowed to decide: execution scheduling/orchestration, transport attachment, runtime reconciliation, projection pipeline routing.
  - What this component must never decide: canonical ABI semantics, acceptance of invalid artifacts, authoritative meaning of wave records.

## Inputs

- Input artifact: canonical wave artifacts from `metaverse-kit`
  - ABI/version: Wave17..Wave31 canonical JSON/NDJSON artifacts
  - Required invariants: digest-valid, schema-valid, ordered traces, replay-safe.
- Input artifact: authority gate doctrine
  - ABI/version: `invariants/authority/**` and documented gate contracts
  - Required invariants: invalid inputs halt emission (`HALT => zero bytes`).

## Outputs

- Output artifact: runtime traces and projection realizations
  - ABI/version: runtime docs and trace outputs under runtime lanes
  - Deterministic encoding: stable replay over identical input and plan
  - Authority class of output: advisory
- Output artifact: orchestration/state plans
  - ABI/version: lattice/plan snapshots and runtime state projections
  - Deterministic encoding: content-addressed or stable diffable plan materialization
  - Authority class of output: advisory

## Forbidden Behavior

- Must not bypass authority gate before emission.
- Must not reinterpret wave artifact semantics.
- Must not write upstream authoritative artifacts directly.
- Must not treat transport/network state as canonical truth.

## Replay Guarantee

- Replay class: deterministic (for declared runtime paths)
- Replay proof method: runtime tests, authority gate checks, deterministic trace regeneration
- Golden coverage: runtime component tests + documented benchmark/proof scripts
- Must-reject coverage: gate refusal, invalid runtime inputs, malformed transport payloads

## Failure Model

- Fail-closed conditions: gate refusal, malformed input artifact, nonconforming runtime plan
- Expected error prefixes/messages: explicit gate/runtime command failures
- Recovery path: correct inputs or runtime plan, rerun gate + runtime checks

## Security / Integrity

- Content-addressing scheme: upstream artifact digests and runtime trace integrity checks
- Signature/receipt requirements: inherit from upstream canonical artifacts where present
- Domain separation statement: hypervisor behavior is downstream of authority semantics
- Trust assumptions: upstream canonical artifacts are already validated by metaverse-kit gates

## Integration Gates

- Required spine step(s): closure-spine-smoke integration when lane is canonical-path
- Required test scripts: runtime world/sync/lattice tests and authority gate tests
- Required fixtures: runtime sample plans and traces
- Required goldens: deterministic runtime replay where declared

## Change Control

- Version bump rule: runtime behavior changes that alter replay outputs require documented contract updates
- Backward compatibility rule: preserve gate semantics and artifact meaning compatibility
- Deprecation path: mark extracted/stub lanes and replacement plan in docs index

## Sign-off

- Author: Codex draft
- Reviewer: pending
- Date (YYYY-MM-DD): 2026-03-05
