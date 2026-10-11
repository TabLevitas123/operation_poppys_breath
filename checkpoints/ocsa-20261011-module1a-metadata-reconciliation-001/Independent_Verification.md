# Independent review: Module 1A metadata reconciliation

**Result (2026-10-11):** The isolated local v0.2.3 checkpoint passes independent integrity and clean-restoration checks. This review covers the metadata repair and its infrastructure gates, not biological validation.

- Archive: `poppy_reconciliation_repair_20261011/releases/v0.2.3/OCSA_v0.2.3-reconciliation.1-local.zip`  
  SHA-256: `f50fe1b1d5f19982feecffd3c633b944835953210c192f03a1e58c68f6a7ace2`
- SQLite database SHA-256: `a152c197fe16af9f57c078327bfde4ee44caf869a9b708815f16e4b62b38a59c`
- Independently checked every one of the archive manifest’s 160 file paths, sizes, and SHA-256 hashes, then extracted it into a clean temporary directory. The extracted database matches the manifest hash; all 31 tests pass; SQL recovery verification and the full local continuity gate pass. SQLite integrity, foreign keys, and the OCSA validator report no blocking findings.
- Compared the repaired database with the untouched v0.2.2 baseline: all historical rows remain, including every claim and claim-to-evidence link. The repair appends 12 source, 4 entity, 8 evidence-locator, and 12 review-scope versions. All 12 claims remain proposed; the canonical graph is empty; no current review is independent; all source-authenticity checks remain partial.
- The review identified and the implementation fixed manifest path-substitution and self-attested-hash bypasses, protection of the original discrepant manifest, stale-review canonical eligibility, a stale-view validation gap, false node-removal reporting from entity supersession, dangling GraphML endpoints, and repeat-migration hash drift. Adversarial regressions are included in the passing suite.

**Remaining limits:** The reconciled manifest confirms bytes in this archived copy; it does not prove when those bytes changed or authenticate their biological contents. Authoritative source-page captures and independent Tier-2 review are still needed before claim acceptance. This checkpoint is local only: no repository push, Library alias update, or durable recovery index was verified. The full local gate reports that the recovery index is absent.
