# Changelog

## Module 1A staging — 2026-07-25

- Added a validated staging package for human MOR/OPRM1, DOR/OPRD1, KOR/OPRK1, and NOP/OPRL1 nomenclature and stable identifiers.
- Added 12 proposed entities, 12 structured evidence excerpts, 12 proposed identity or mapping assertions, and 12 pass-2 field verifications.
- Added search, source, evidence, verification, validation, test, graph-diff, changeset, open-question, run, and file manifests.
- Passed 18 static staging-integrity tests, including identifier-format, excerpt-hash, uniqueness, proposed-state, canonical-eligibility, and NOP-versus-KOR separation checks.
- Preserved all assertions in `proposed` state; accepted claims and canonical graph changes remain zero.
- Recorded two blocking conditions: source-page files are not yet archived by content hash, and the hardened SQLite database was not materialized for proposed-state ingestion.
- Published the checkpoint as run `ocsa-20260725-module1-receptor-identifiers-001` and merged it through pull request #2.
- Did not issue a canonical database release or claim literature saturation.

## Unreleased — persistence recovery — 2026-07-24

- Restored the ordinary, directly inspectable OCSA source tree to the active branch.
- Preserved the content-hashed hardened-source archive as a secondary recovery copy.
- Removed dependence on one-use or self-modifying materialization workflows for routine persistence.
- Declared GitHub as the durable source of truth and `/mnt/data` as temporary scratch storage.
- Added a persistence policy, repository checkpoint, source map, run report, and machine-readable changeset.
- Added no scientific source, evidence span, entity, claim, contradiction, node, or edge.

## Legacy bootstrap — 2026-07-23

Initial Module 0 schema, store, tests, configuration, protocol, and validation workflow.
