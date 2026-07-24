# Operation Poppy's Breath

Operation Poppy's Breath maintains the Opioid Causal Systems Atlas (OCSA), a provenance-first biomedical research database and causal atlas for opioid systems and their interactions with pain, reward, respiration, tolerance, dependence, withdrawal, overdose, and harm-reduction mechanisms.

This repository is the project's durable source of truth. `/mnt/data` and other session-local workspaces are temporary scratch space only.

## Persistence contract

At the beginning of every research run, read the repository state before doing new work. At the end of every validated checkpoint, commit and push the actual working source, schemas, manifests, reports, exports, database snapshots, and versioned release artifacts needed to resume after a workspace reset.

Do not rely solely on conversation memory, an unpushed `/mnt/data` directory, ephemeral workflow artifacts, or a hidden archive. Recovery archives may exist as secondary backups, but the ordinary source tree must remain directly inspectable and cloneable.

See [`PERSISTENCE.md`](PERSISTENCE.md) for the detailed contract.

## Current visible source

- `schema.sql` — SQLite schema.
- `src/ocsa_store.py` — database initialization and validation entry point.
- `tests/test_store.py` — automated validation tests.
- `config.json` — project configuration.
- `RUN_PROTOCOL.md` — run and repository update protocol.
- `.github/workflows/validate.yml` — repository validation workflow.
- `.bootstrap/hardened-source/` — content-hashed secondary recovery archive retained for disaster recovery, not as the primary working tree.

## Scientific boundary

The program constructs an evidence-traceable scientific atlas. It does not design, synthesize, optimize, or provide production instructions for illicit or untested drugs.

## Current scientific state

This persistence-recovery checkpoint adds no biomedical source, paper dossier, evidence span, biological entity, scientific claim, contradiction, graph node, or graph edge. Scientific ingestion remains blocked until Module 0 infrastructure hardening is completed against the directly visible source tree.
