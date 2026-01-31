# Phase 24 — mind-git Projection Layer (Read-Only)

This pipeline ingests lattice artifacts and projects:
- content-addressed objects
- summary indexes
- Obsidian Canvas views
- human-readable “why it changed” reports

All outputs are **non-authoritative** and reproducible from trace + plans.

## Run

```sh
bash pipelines/mind-git/run.sh
```

## Outputs

- `projections/mind-git/store/*.json` (content-addressed objects)
- `projections/mind-git/index/ingest.jsonl`
- `projections/mind-git/index/latest.json`
- `projections/mind-git/canvas/PeerGraph.canvas`
- `projections/mind-git/reports/basis-flip.md`
- `projections/mind-git/reports/plan-history.md`
- `reports/phase24-transcript.txt`
