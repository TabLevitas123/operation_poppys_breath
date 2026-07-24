# Persistent checkpoint verification

Run ID: `ocsa-20260724-module0-hardening-001`  
Verified: 2026-07-24  
Target: `main`

The complete Module 0 infrastructure-hardening checkpoint is persisted under this directory in the canonical GitHub repository.

## Upload verification

GitHub returned a successful commit SHA for:

- the checkpoint manifest;
- the fail-closed materializer;
- the checkpoint README;
- every archive chunk from `part-000.b64` through `part-014.b64`;
- `checkpoints/LATEST.json`; and
- the root README update.

GitHub API readback subsequently confirmed:

- `checkpoints/LATEST.json` with the expected run, release, archive hash, and database hash;
- the complete manifest containing all fifteen part records and their expected SHA-256 hashes and sizes; and
- the final transport chunk at `chunks/part-014.b64`.

The latest visible repository commit after publication was `13965f09afa951e783ac750653209569fef6f462`, titled `Document latest validated OCSA persistent checkpoint`.

## Pre-publication validation

Before upload, the release archive was rebuilt twice with an identical SHA-256, reconstructed from its Base64 transport byte-for-byte, restored into a clean local directory, and its database and test suite were executed successfully.

- Archive SHA-256: `3ea0d3e47398b4b41dc9673c94359dffbf9aa543ef7e943e3ab842229174cc56`
- Database SHA-256: `f8f7509d5e371527cfbf39ea73d808416e4a2b71472114a62485c7c1bea81ab9`
- Validation blocking findings: `0`
- Validation warnings: `0`
- Automated tests: `14 passed`

A fresh unauthenticated `git clone` was attempted from the execution container after publication, but that container could not resolve `github.com`. This was an execution-environment DNS restriction, not a GitHub write failure. Repository persistence was therefore verified through successful write commits and connected GitHub API readback rather than by claiming a clone that did not occur.

## Scientific boundary

No biomedical source, paper dossier, evidence span, biological entity, scientific claim, contradiction, graph node, or graph edge was ingested.
