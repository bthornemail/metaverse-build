# Projections

Downstream projection outputs - views, not truth.

## Mind-Git Projection

The mind-git pipeline produces operator-facing views from world state.

### Run

```bash
bash pipelines/mind-git/run.sh
```

### Export to Vault

```bash
bash pipelines/mind-git/export-vault.sh
```

### Directories

- `canvas/` - Canvas rendering outputs
- `index/` - Searchable index
- `plan-history/` - Plan history
- `reports/` - Generated reports
- `store/` - Projection store

### Outputs

- `projections/mind-git/store/*.json` - content-addressed objects
- `projections/mind-git/index/ingest.jsonl` - ingest index
- `projections/mind-git/index/latest.json` - latest index
- `projections/mind-git/canvas/PeerGraph.canvas` - Obsidian canvas
- `projections/mind-git/reports/basis-flip.md` - basis flip report
- `projections/mind-git/reports/plan-history.md` - plan history
- `reports/phase24-transcript.txt` - phase transcript

### Contract

Projections are:
- Non-authoritative
- Git-ignored (in `.gitignore`)
- Disposable and rebuildable
- Derived from trace
- Reproducible from trace + plans

### Export

```bash
# Export vault (operator cockpit)
bash pipelines/mind-git/export-vault.sh
```

The vault is the operator cockpit - safe to delete, rebuildable at any time.
