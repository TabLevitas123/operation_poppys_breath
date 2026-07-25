# Local-first execution rule

1. Inspect `/mnt/data/operation_poppys_breath` first.
2. Run `python scripts/continuity_guard.py verify --full`.
3. When the local gate passes, begin work immediately without checking GitHub or the Library.
4. When the local gate fails or the workspace is absent, do not perform research. Materialize `/Operation_Poppys_Breath/RECOVERY_INDEX.json`, `/Operation_Poppys_Breath/OCSA_LATEST.zip`, and `/Operation_Poppys_Breath/BOOTSTRAP_RESTORE.py` from the persistent Library; restore and verify them first.
5. Use GitHub as the secondary recovery route and source/audit history, not as a mandatory start-of-run check.
6. Never replace newer valid local work with older durable content merely because the older copy is easier to retrieve.

Current status: checkpoint `ocsa-20260725-continuity-hardening-001` has passed local validation, clean archive restoration, Library upload, Library download, clean simulated-reset restoration, and 22 automated tests.
