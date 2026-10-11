# Module 1A append-only metadata reconciliation

Run: ocsa-20261011-module1a-metadata-reconciliation-001. Local isolated copy only; no repository push or durable alias update.

- Baseline DB SHA-256: c220167791352e524586bd1be6fd3a43eebb05aa9a2663c1d016b319f22173a2
- Current DB SHA-256: a152c197fe16af9f57c078327bfde4ee44caf869a9b708815f16e4b62b38a59c
- Appended records: 12 source versions, 4 receptor entity versions, 8 evidence-locator revisions, 12 historical review-scope revisions. Original rows and historical claim/evidence references are unchanged.
- Cytobands reside in entity_versions.chromosomal_location, separate from identifiers_json.
- The old staging FILE_MANIFEST.json remains intact. It disagrees on three archived files; FILE_MANIFEST_RECONCILED.json verifies their current bytes against the historical outer release manifest and explicitly does not authenticate historical metadata or biological accuracy.
- Source-file archival remains absent, review independence remains same-model/non-independent, claims remain proposed, canonical graph remains empty.
- Graph diff: 4 versioned nodes changed; zero logical nodes or edges removed; no mass-change halt.
- SQLite integrity, foreign keys, OCSA validation, SQL recovery restoration, and targeted tests pass. See validation/test reports for exact checks.
- No new scientific assertions, pharmacological design, or source re-authentication occurred.
