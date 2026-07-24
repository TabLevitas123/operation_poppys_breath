# Changelog

## 0.2.1 — 2026-07-24

Infrastructure repair candidate.

- Replaced the bootstrap-only draft architecture with a directly inspectable schema, store, test suite, reports, exports, snapshots, and release workflow.
- Enforced proposed-first claim creation and accepted-only canonical graph exposure.
- Added immutable source versions and source-file hashes, exact evidence spans and excerpt hashes, source and claim verification records, claim and entity versioning, contradiction versions, append-only change and run events, stored validation runs, graph diffs, snapshots, release records, and deterministic exports.
- Added structural, source, evidence, semantic, logical, numerical, graph-diff, snapshot, and release validation.
- Added deliberate corruption-injection tests, deterministic test-report normalization, clean restoration verification, and tamper-detecting binary artifact materialization.
- Added a hash-verified Base64 transport only for the deterministic binary release; source, schema, tests, reports, manifests, and exports remain directly inspectable.
- Recorded that the preceding 0.2.0 pull-request draft was not merged and did not represent a valid published release.
- Ingested no scientific source, evidence span, entity, claim, or graph edge.

## 0.1.0 — legacy bootstrap

Initial bootstrap-only repository. Its concealed database was not directly auditable through the connected repository interface and is treated as a migration input, not a validated scientific release.
