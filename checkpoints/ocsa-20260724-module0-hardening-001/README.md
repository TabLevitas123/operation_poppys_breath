# OCSA Module 0 hardening checkpoint

Run ID: `ocsa-20260724-module0-hardening-001`  
Release: `v0.2.0-infra-checkpoint.1`  
Date: 2026-07-24

This directory persists the complete locally validated checkpoint independently of `/mnt/data`. The archive contains the hardened schema, Python store, tests, clean SQLite database, pre-run/post-staging/post-run snapshots, deterministic graph exports, manifests, changeset, validation report, test report, run report, and release tooling.

Scientific sources, biological entities, claims, contradictions, graph nodes, and graph edges in this checkpoint: **0**.

Validation before publication:

- final database validation: passed;
- blocking findings: 0;
- warnings: 0;
- automated tests: 14 passed;
- archive rebuilt twice with an identical SHA-256;
- Base64 reconstruction matched the original archive byte-for-byte;
- clean archive restoration: passed;
- restored database validation: passed;
- restored test suite: passed.

Archive SHA-256: `3ea0d3e47398b4b41dc9673c94359dffbf9aa543ef7e943e3ab842229174cc56`  
Database SHA-256: `f8f7509d5e371527cfbf39ea73d808416e4a2b71472114a62485c7c1bea81ab9`

Restore from a fresh clone:

```bash
python checkpoints/ocsa-20260724-module0-hardening-001/materialize.py \
  --extract-output operation_poppys_breath_v0.2.0

cd operation_poppys_breath_v0.2.0
python src/ocsa_store.py --db atlas.db --schema schema.sql --root . validate
python -m unittest discover -s tests -v
```

The materializer verifies every chunk, the decoded archive, safe ZIP paths, CRCs, and every member listed in the internal release manifest before reporting success.
