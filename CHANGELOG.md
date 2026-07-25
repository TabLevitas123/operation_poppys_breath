# Changelog

## v0.2.2 — workspace recovery and re-hardening — 2026-07-25

- Restored the complete v0.1.0 workspace from the persistent ChatGPT file Library after `/mnt/data` reset.
- Preserved the recovered v0.1.0 archive, database, schema, and test fixture under `legacy/`.
- Rebuilt the scientific store with proposed-first claims, accepted-only canonical graph gating, immutable source files and source versions, exact evidence spans, entity and claim versioning, contradictions, append-only change histories, validation records, graph diffs, snapshots, deterministic exports, release records, and hash-chained run events.
- Restored Module 1A receptor identifier staging for OPRM1, OPRD1, OPRK1, and OPRL1.
- Ingested 12 entities, 12 evidence spans, 12 proposed assertions, 12 pass-2 same-model checks, and 4 open questions.
- Kept all claims proposed because immutable authoritative source files and independent Tier-2 review are still absent.
- Canonical graph changes: zero.
- Added corruption-injection tests and clean release restoration testing.

## v0.1.0 — initial local research store — 2026-07-23

Initial SQLite store, search/export tooling, empty scientific dataset, and release archive.

## Continuity hardening — 2026-07-25

- Added a fail-closed local startup gate that verifies required files, recorded hashes, SQLite integrity, foreign keys, OCSA validation, and the test suite.
- Added an atomic bootstrap restorer that verifies archive safety, member hashes, database hash, SQLite integrity, OCSA validation, and tests before replacing a workspace.
- Defined the ChatGPT file Library as the binary recovery authority and GitHub as the source/audit authority.
- Added stable and versioned recovery-path conventions so `/mnt/data` resets require no user-uploaded ZIP.
- Separated external archive-hash pointers from archive contents to eliminate self-referential and stale checkpoint hashes.

## Repository snapshot reconciliation — 2026-07-25

- Preserved the user-supplied repository ZIP immutably at `legacy/repository-snapshots/operation_poppys_breath-main-608dc611ddc80e9ce0979ac0081f6bd87ebca3181cc49831872ec833d9bb9a94.zip` with SHA-256 `608dc611ddc80e9ce0979ac0081f6bd87ebca3181cc49831872ec833d9bb9a94`.
- Restored the exact richer Module 1A staging package from that repository snapshot.
- Preserved the earlier shortened reconstruction under `runs/ocsa-20260725-module1-receptor-identifiers-001/recovered-rebuild-before-repo-reconciliation/` for auditability.
- Recorded the remaining append-only database reconciliation work instead of mutating existing provenance records in place.
- Changed no accepted claim, canonical node, or canonical edge.
