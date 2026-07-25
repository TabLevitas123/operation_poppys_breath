# GitHub disaster-recovery route

The ChatGPT Library archive is the primary exact binary recovery route. This directory is an independent GitHub-only route for cases where the Library is unavailable.

It contains content-hashed bundles for the hardened source, finalized continuity overlays, logical SQLite dump, and database snapshots. The restorer verifies every bundle, reconstructs `atlas.db`, checks the global logical database digest, runs all 23 tests, and creates a fresh exact local checkpoint before reporting success.

```bash
python scripts/restore_github_fallback.py \
  --repository-root . \
  --target /mnt/data/operation_poppys_breath
```

The reconstructed SQLite file may have a different physical SHA-256 than the Library database because SQLite serialization is not canonical. Its logical digest, per-table hashes, table counts, validation result, and scientific state must match exactly.
