# Operation Poppy's Breath

Operation Poppy's Breath is the research program that maintains the Opioid Causal Systems Atlas (OCSA), a provenance-first, versioned causal knowledge base for opioid receptors and the biological systems that shape opioid reward, relief, analgesia, respiratory depression, tolerance, dependence, withdrawal, overdose, and mortality.

This repository is scientific infrastructure, not a drug-design or drug-production project. It must not be used to design, synthesize, optimize, or provide production instructions for illicit or untested drugs.

## Trust boundary

The authoritative chain is:

`immutable source → exact evidence span → structured observation → proposed claim → independent verification → accepted claim → canonical graph edge`

A new claim must begin in `proposed`. The `canonical_graph` view contains only the current version of an `accepted` claim that also has:

1. an immutable source file bound by SHA-256;
2. an exact evidence span and excerpt hash;
3. a passing source-authenticity record;
4. a blind pass-2 claim verification;
5. preserved context and valid causal language; and
6. an independent Tier-2-or-higher approval.

Proposed, disputed, rejected, retracted, duplicate, and insufficient-evidence records remain auditable but cannot silently enter the canonical graph.

## Repository layout

- `atlas.db` — current SQLite candidate database after artifact materialization.
- `schema.sql` — append-only, versioned scientific and audit schema.
- `src/ocsa_store.py` — initialization, validation, snapshot, graph-diff, and export utility.
- `tests/` — normal and deliberate corruption-injection tests.
- `exports/` — deterministic canonical, provisional, full-research, contradiction, evidence, and source exports.
- `snapshots/` — pre-run, staging, and post-run SQLite snapshots.
- `manifests/` — source, search, database, and repository manifests.
- `reports/` — infrastructure audit, run report, validation report, graph diff, and test report.
- `changesets/` — machine-readable run changesets.
- `releases/` — versioned archives, release manifests, release notes, restoration reports, and a hash-verified text transport for binary artifacts.

## Binary artifact materialization

The connected repository writer publishes ordinary source, schema, tests, reports, manifests, and graph exports as directly readable files. The SQLite database, SQLite snapshots, and deterministic release ZIP are represented remotely by the ZIP's hash-verified Base64 transport under `releases/v0.2.1/archive-b64/`. They are not authoritative until all part hashes, the decoded archive hash, the internal release manifest, and the extracted file hashes pass.

After cloning, reconstruct those binary artifacts with:

```bash
python scripts/materialize_artifacts.py \
  --root . \
  --manifest releases/v0.2.1/archive-b64/transport-manifest.json
sha256sum --check SHA256SUMS
```

The materializer refuses to replace a different existing artifact unless `--force` is explicitly supplied.

## Local validation

The project intentionally uses the Python standard library and SQLite only.

```bash
python src/ocsa_store.py --db build/clean.db --schema schema.sql --root . init
python src/ocsa_store.py --db build/clean.db --schema schema.sql --root . validate
python -m unittest discover -s tests -v
python scripts/build_release.py --root . --timestamp 2026-07-24T15:30:00Z
python scripts/verify_release.py releases/v0.2.1/OCSA_v0.2.1-infra.zip
```

## Current scientific state

No scientific source, paper dossier, evidence span, receptor entity, scientific claim, or graph edge is accepted in this infrastructure checkpoint. Module 1 may begin only after the infrastructure pull request passes remote CI and is merged.
