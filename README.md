# Operation Poppy's Breath — Opioid Causal Systems Atlas

OCSA is a provenance-first, versioned causal atlas for opioid biology and harm-reduction research. It does not provide illicit-drug synthesis, optimization, or production instructions.

## Current local state

- Schema and validator: `0.2.2`
- Active database: `atlas.db`
- Module 1A human receptor identifier seed: restored and ingested as proposed-only records
- Canonical claims: `0`
- Provisional claims: `12`
- Canonical graph edges: `0`

The evidence chain is:

`immutable source → exact evidence span → structured observation → proposed claim → independent verification → accepted claim → canonical graph edge`

New claims must begin as `proposed`. Only current accepted versions satisfying source-file, evidence-span, authenticity, independent pass-2 review, context, and review-tier gates enter `canonical_graph`.

## Local-first startup

When this directory survives between responses, begin here without checking GitHub:

```bash
python src/ocsa_store.py --db atlas.db --schema schema.sql --root . validate
python src/ocsa_store.py --db atlas.db --schema schema.sql --root . stats
```

Use GitHub or the Library only if the local state is missing or invalid. See `LOCAL_FIRST.md` and `PERSISTENCE.md`.

## Validation

```bash
python -m unittest discover -s tests -v
python src/ocsa_store.py --db atlas.db --schema schema.sql --root . validate
python scripts/verify_release.py releases/v0.2.2/OCSA_v0.2.2-recovered-hardened.zip
```
## Automatic recovery after a workspace reset

The project uses a fail-closed continuity system. Normal runs start locally with `python scripts/continuity_guard.py verify --full` and do not check GitHub when the workspace is valid. After a reset, the stable archive, database, recovery index, and bootstrap restorer are materialized from the ChatGPT file Library. Research cannot resume until the cleanly restored workspace passes cryptographic file checks, SQLite integrity, OCSA validation, and all automated tests. GitHub remains the independent source and audit history. See `CONTINUITY_CONTRACT.md`.

