# Lattice Runtime Substrate (metaverse-build/runtime/lattice)

Purpose: structural discovery + connection management only.
Outputs are **non-authoritative** and feed the semantic kernel via a narrow interface.

Artifacts:
- `state/peers/observed.jsonl`
- `state/graph/peergraph.json`
- `state/graph/basis.json`
- `state/plan/connection-plan.json`
- `state/traces/discovery.log`

Entry points:
- `bin/beacon-listen.sh`
- `bin/peer-observer.sh`
- `bin/graph-basis-compiler.sh`
- `bin/run.sh`
