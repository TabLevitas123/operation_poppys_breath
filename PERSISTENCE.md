# OCSA persistence and recovery contract

`/mnt/data/operation_poppys_breath` is the active workspace. Use it immediately when the fail-closed local gate passes:

```bash
python scripts/continuity_guard.py verify --full
```

Do not inspect GitHub or the Library first when that command succeeds.

The ChatGPT file Library is the primary binary recovery layer because its files can be materialized directly into a fresh `/mnt/data` container. The stable recovery objects are:

- `/Operation_Poppys_Breath/RECOVERY_INDEX.json`
- `/Operation_Poppys_Breath/OCSA_LATEST.zip`
- `/Operation_Poppys_Breath/atlas_latest.db`
- `/Operation_Poppys_Breath/BOOTSTRAP_RESTORE.py`

Versioned archives and databases are stored under `/Operation_Poppys_Breath/checkpoints/` and are never overwritten. GitHub stores normal source files, tests, manifests, run records, and history as an independent source/audit layer.

When the local gate fails, no research may continue until the stable Library archive is restored and independently passes member hashes, database hash, SQLite checks, OCSA validation, and the test suite. GitHub recovery is used only when the Library recovery objects are inaccessible or invalid.

At the end of every substantive run, build a new deterministic checkpoint, verify it through clean extraction, upload both stable and versioned Library copies, push source/audit changes to GitHub, download the stable Library archive again, and reverify it. See `CONTINUITY_CONTRACT.md` for the complete procedure.

GitHub also stores `recovery/atlas.sql` and `recovery/atlas-sql-manifest.json`. These form an independent text-based database recovery path. A restored SQL database must match the recorded global logical digest, every per-table digest, and every table count before it is accepted.
