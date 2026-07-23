# Operation Poppy's Breath

Research infrastructure for the Opioid Causal Systems Atlas (OCSA): a provenance-first, versioned knowledge graph and retrieval store for mapping opioid receptors, signaling, cells, circuits, physiology, clinical outcomes, contradictions, and open questions.

## Current repository payload

The complete committed project is preserved as a Git bundle encoded in Base64 under `.bootstrap/`. The bundle contains the SQLite atlas, schema, Python store, tests, exports, validation workflow, manifests, and versioned snapshots.

The canonical local commit represented by the bundle is:

`0c3c1984e75b52bc2d8f55d637b72cf150434bc8`

## Restore the complete repository

Clone this repository, then run:

```bash
cat .bootstrap/part-*.b64 > operation_poppys_breath.bundle.b64
base64 --decode operation_poppys_breath.bundle.b64 > operation_poppys_breath.bundle
git bundle verify operation_poppys_breath.bundle
git clone operation_poppys_breath.bundle operation_poppys_breath-restored
cd operation_poppys_breath-restored
git checkout main
```

Before relying on a restored copy, verify the bundle SHA-256 against `.bootstrap/SHA256SUMS` and run the included test and validation commands.

## Scientific integrity policy

Vector similarity is retrieval only, never evidence. Claims begin in quarantine and may enter the canonical graph only after source identity verification, exact evidence anchoring, schema validation, independent extraction review, contradiction checks, and a recorded audit trail.

No scientific claims have been ingested in the initial infrastructure release.
