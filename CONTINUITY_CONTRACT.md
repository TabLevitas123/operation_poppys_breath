# OCSA continuity contract

This contract prevents a workspace reset from silently turning a partial reconstruction into the active research state.

## Storage roles

1. **Active workspace:** `/mnt/data/operation_poppys_breath` is used for normal work.
2. **Binary recovery authority:** the ChatGPT file Library stores a stable latest archive, a versioned archive, the matching SQLite database, a recovery index, and the standalone bootstrap restorer.
3. **Source and audit authority:** GitHub stores ordinary source files, schemas, tests, run records, manifests, and checkpoint history.

No single layer is sufficient by itself.

## Start-of-run gate

Always inspect the active workspace first. Do not inspect GitHub or the Library when all of the following pass locally:

- `scripts/continuity_guard.py verify --full`;
- the database SHA-256 matches the local recovery index;
- SQLite integrity and foreign-key checks pass;
- the OCSA validator passes;
- the automated tests pass.

When the local workspace is absent or fails the gate, stop all research work. Restore the stable Library archive using `BOOTSTRAP_RESTORE.py`, then rerun the full gate. GitHub is the fallback when the Library copy is unavailable or fails cryptographic verification.

## End-of-run gate

A run is not complete until all of these occur:

1. The database is checkpointed out of WAL mode and validated.
2. Tests pass.
3. Deterministic exports, reports, manifests, changeset, and snapshots are updated.
4. A deterministic archive is built.
5. The archive is extracted into a clean directory.
6. Every member hash, the database hash, SQLite integrity, OCSA validation, and tests pass in the clean restoration.
7. The versioned archive and database are uploaded to the Library.
8. Stable Library aliases are replaced with the newly verified bytes.
9. A recovery index containing hashes and Library file identifiers is uploaded.
10. Ordinary source and audit files are pushed to GitHub.
11. The stable Library archive is downloaded again and reverified.

If any step fails, the checkpoint is incomplete and must not become the latest recovery pointer.

## Scientific safety

Recovery status is independent of scientific review status. A technically valid checkpoint may still contain only proposed claims. Restoration must never promote a claim, alter review tiers, or change the canonical graph.

## Limits of the guarantee

This protocol guarantees detection and automatic recovery for ordinary `/mnt/data` resets as long as at least one durable recovery layer remains accessible. No system can guarantee survival of a simultaneous loss of the local workspace, the ChatGPT Library, GitHub, and the account credentials needed to access them. The independent copies and cryptographic checks make silent partial recovery extremely unlikely and prevent research from continuing on an unverified state.

## GitHub-independent data reconstruction

Every completed checkpoint must also export `recovery/atlas.sql` and `recovery/atlas-sql-manifest.json`. The manifest records a physical database hash, a deterministic logical digest, per-table hashes, and row counts. A clean database reconstructed from the SQL must match every logical digest and pass SQLite and OCSA validation. These text files are pushed to GitHub, so the full scientific and provenance state can be reconstructed even when the binary Library archive is unavailable.

No database-only mutation is permitted. Every scientific change must also exist in the immutable run package, changeset, and SQL recovery snapshot before the checkpoint may become current.
