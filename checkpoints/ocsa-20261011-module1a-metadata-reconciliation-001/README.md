# OCSA v0.2.3 reconciliation checkpoint

This is a separately published, independently checked checkpoint. The repository's root runtime and main-branch recovery pointers are not changed by this publication. This pull request is a draft for review, not a merge or promotion.

## Restore

Download `OCSA_v0.2.3-reconciliation.1.zip`, verify its SHA-256 below, and extract into a fresh directory. The archive is the complete runnable checkpoint. The `source/` directory beside it exposes code and audit files for review; it is not a standalone installation because fixtures and snapshots remain inside the archive.

From the extracted archive, run:

```sh
python -m unittest discover -s tests -v
python src/ocsa_store.py --db atlas.db --schema schema.sql --root . validate
python scripts/continuity_guard.py verify --full
```

The archive README retains a stale release-verification example pointing to v0.2.2. To verify this delivered archive, use `python scripts/verify_release.py /actual/path/to/OCSA_v0.2.3-reconciliation.1.zip` instead. This note does not change the independently reviewed archive bytes.

## Verification and scope

- Archive SHA-256: `f50fe1b1d5f19982feecffd3c633b944835953210c192f03a1e58c68f6a7ace2`
- Database SHA-256: `a152c197fe16af9f57c078327bfde4ee44caf869a9b708815f16e4b62b38a59c`
- Independent local checks: all 160 manifested members, 31 tests, SQL recovery, and full continuity gate passed after clean extraction.
- Existing root CI is a separate legacy runtime check; it does not validate this nested checkpoint. The attached independent report states what was actually tested.
- Appended: 12 source versions, 4 entity versions, 8 evidence-locator revisions, 12 historical review-scope revisions. Original scientific records remain unchanged.
- All 12 scientific claims remain proposed. Canonical claims: zero. No new biological finding, source re-authentication, source-page archival, or review-independence upgrade.
- Stable Library aliases and main recovery index remain unchanged. Versioned copies are saved privately in Library. The report's local-only wording describes its verification-time state; this publication adds a separate repository copy.

## Next dependency

Review integration and durable recovery-pointer promotion separately. Then acquire and content-hash authoritative receptor source records and perform independent scientific verification before promoting any claims.
