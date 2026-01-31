# Phase 24 — mind-git Projection Contract

mind-git artifacts are **projection-only**.

Rules:
- Outputs are reproducible from trace + plans.
- No outputs are consumed by lattice-runtime without re-entering through authority + trace.
- No publishing to bus or network from mind-git tooling.
- No authority claims: mind-git is a VCM/workspace lens, not truth.

Inputs (authoritative):
- runtime/lattice/trace/discovery.log
- runtime/lattice/trace/routing.log
- runtime/lattice/graph/peergraph.json
- runtime/lattice/graph/basis.json
- runtime/lattice/plan/connection-plan.json
- reports/*.txt (evidence only)

Outputs (non-authoritative):
- projections/mind-git/store/*.json (content-addressed objects)
- projections/mind-git/index/*.json*
- projections/mind-git/canvas/*.canvas
- projections/mind-git/reports/*.md
