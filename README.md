# Operation Poppy's Breath

Operation Poppy's Breath maintains the Opioid Causal Systems Atlas (OCSA), a provenance-first biomedical research database and causal atlas for opioid systems and their interactions with pain, reward, respiration, tolerance, dependence, withdrawal, overdose, and harm-reduction mechanisms.

This repository is the project's durable source of truth. `/mnt/data` and other session-local workspaces are temporary scratch space only.

## Persistence contract

At the beginning of every research run, read the repository state before doing new work. At the end of every validated checkpoint, commit and push the actual working source, schemas, manifests, reports, exports, database snapshots, and versioned release artifacts needed to resume after a workspace reset.

Do not rely solely on conversation memory, an unpushed `/mnt/data` directory, or an ephemeral workflow artifact. See [`PERSISTENCE.md`](PERSISTENCE.md) for the detailed contract.

## Latest validated persistent checkpoint

The canonical resume pointer is [`checkpoints/LATEST.json`](checkpoints/LATEST.json).

Current checkpoint:

- Run: `ocsa-20260724-module0-hardening-001`
- Release: `v0.2.0-infra-checkpoint.1`
- Archive SHA-256: `3ea0d3e47398b4b41dc9673c94359dffbf9aa543ef7e943e3ab842229174cc56`
- Database SHA-256: `f8f7509d5e371527cfbf39ea73d808416e4a2b71472114a62485c7c1bea81ab9`
- Scientific claims: `0`

The checkpoint contains the hardened schema, source, tests, clean SQLite database, pre-run/post-staging/post-run snapshots, deterministic graph exports, manifests, changeset, validation report, test report, run report, and release tooling. Its Base64 chunks and decoded ZIP are independently hashed.

Restore from a fresh clone without relying on `/mnt/data`:

```bash
python checkpoints/ocsa-20260724-module0-hardening-001/materialize.py \
  --extract-output operation_poppys_breath_v0.2.0

cd operation_poppys_breath_v0.2.0
python src/ocsa_store.py --db atlas.db --schema schema.sql --root . validate
python -m unittest discover -s tests -v
```

Until the hardened files are promoted into the repository root, the checkpoint identified by `checkpoints/LATEST.json` is the authoritative restart state. The root-level source files may represent an earlier visible scaffold and must not override the newer checkpoint merely because they are easier to inspect.

## Current visible source

- `schema.sql` — root-level SQLite scaffold.
- `src/ocsa_store.py` — root-level database utility scaffold.
- `tests/test_store.py` — root-level validation tests.
- `config.json` — project configuration.
- `RUN_PROTOCOL.md` — run and repository update protocol.
- `.github/workflows/validate.yml` — repository validation workflow.
- `checkpoints/` — versioned, self-verifying persistent restart states.
- `.bootstrap/hardened-source/` — older content-hashed recovery material retained for provenance.

## Scientific boundary

The program constructs an evidence-traceable scientific atlas. It does not design, synthesize, optimize, or provide production instructions for illicit or untested drugs.

## Current scientific state

The latest checkpoint adds no biomedical source, paper dossier, evidence span, biological entity, scientific claim, contradiction, graph node, or graph edge. Module 1 has not begun.
