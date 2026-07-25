# START HERE — Operation Poppy’s Breath / OCSA

This ChatGPT Project is the dedicated, Project-only working environment for **Operation Poppy’s Breath**, whose primary product is the **Opioid Causal Systems Atlas (OCSA)**.

OCSA is a provenance-first, versioned causal atlas designed to investigate whether beneficial opioid effects—analgesia, craving suppression, emotional relief, withdrawal relief, and euphoria—can be separated mechanistically from respiratory depression, overdose, sedation, airway failure, tolerance, dependence, and reinforcement.

## Certified starting point

- Release: `v0.2.2-continuity.6`
- Checkpoint: `ocsa-20260725-continuity-hardening-006`
- GitHub: `TabLevitas123/operation_poppys_breath`, branch `main`, continuity merge `9c8f3d345dc9371ccde40a44889fe6c8a07d301d`
- Expected active workspace: `/mnt/data/operation_poppys_breath`
- Active database: `atlas.db`, 307,200 bytes, SHA-256 `c220167791352e524586bd1be6fd3a43eebb05aa9a2663c1d016b319f22173a2`
- Schema/validator: `0.2.2`
- Current scientific state: 12 source records, 12 entities, 12 evidence spans, 12 proposed assertions, 12 same-model Pass-2 checks, 4 open questions, 0 accepted claims, 0 contradictions, and 0 canonical edges.

## Read these first, in order

1. `START_HERE.md`
2. `PROJECT_INDEX.md`
3. `CURRENT_STATE.md`
4. `PROJECT_SOURCE_PRECEDENCE.md`
5. `PROJECT_OPERATING_MANUAL.md`
6. `CONTINUITY_CONTRACT.md`
7. `RUN_PROTOCOL.md`
8. `FINAL_CHECKPOINT.json`, `CHECKPOINT_CONTENT.json`, `RECOVERY_INDEX.json`, and `WORKSPACE_STATE.json`
9. `config.json`, `schema.sql`, and `MIGRATION_BASELINE_VALIDATION.json`
10. The Module 1 and current scientific-state files relevant to the active workstream.

`CURRENT_STATE.md` is the authoritative human-readable state summary. `PROJECT_OPERATING_MANUAL.md` contains the detailed scientific and operational rules. `PROJECT_SOURCE_PRECEDENCE.md` controls conflicts.

## Recovery after a reset

Inspect `/mnt/data/operation_poppys_breath` first. If the local gate passes, work locally without checking GitHub. If the workspace is absent or invalid, restore `OCSA_RECOVERY_ARCHIVE.zip` with `BOOTSTRAP_RESTORE.py`, verify the expected archive hash `a622851d272a667e5748d8d4f3efa419d6a0be1e414e4a2ac144d018bc0067ff`, then run the documented continuity gate. Use `GITHUB_FALLBACK_RESTORE.py` only as the documented secondary route. Do not mix versions or overwrite newer validated local work.

## Next documented task

Run an append-only Module 1A metadata-reconciliation unit from `MODULE1_DATABASE_RECONCILIATION_PENDING.json`. Append the richer aliases, chromosomal locations, source metadata, evidence-locator precision, and verification-scope fields without editing prior versions in place. Keep every assertion proposed. After reconciliation, archive lawful authoritative NCBI, UniProt, and IUPHAR records by content hash before any claim can advance toward acceptance.
