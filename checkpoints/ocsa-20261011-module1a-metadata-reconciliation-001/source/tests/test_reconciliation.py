from __future__ import annotations

import json
import shutil
import sqlite3
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))
sys.path.insert(0, str(ROOT / "scripts"))
from ocsa_store import AtlasStore, sha256_file
from sql_recovery import logical_inventory

RUN_DIR = ROOT / "runs" / "ocsa-20260725-module1-receptor-identifiers-001"
SNAPSHOT = ROOT / "snapshots" / "ocsa-20260725-module1-receptor-identifiers-001-post-run.db"


class ReconciliationTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.db = Path(self.tmp.name) / "atlas.db"
        shutil.copyfile(SNAPSHOT, self.db)  # Portable unmodified 0.2.2 fixture.
        self.store = AtlasStore(self.db, ROOT / "schema.sql", ROOT)

    def test_old_database_migrates_without_rewriting_scientific_rows(self):
        with self.store.connection() as con:
            before = {table: [dict(r) for r in con.execute(f"SELECT * FROM {table} ORDER BY 1")]
                      for table in ("source_versions", "entity_versions", "evidence_spans", "claim_reviews")}
        self.store.migrate_reconciliation_schema()
        with self.store.connection() as con: con.execute("PRAGMA wal_checkpoint(TRUNCATE)")
        migrated_hash = sha256_file(self.db)
        self.store.migrate_reconciliation_schema()
        with self.store.connection() as con: con.execute("PRAGMA wal_checkpoint(TRUNCATE)")
        self.assertEqual(migrated_hash, sha256_file(self.db))
        with self.store.connection() as con:
            for table, rows in before.items():
                after = [{k: r[k] for k in rows[0]} for r in con.execute(f"SELECT * FROM {table} ORDER BY 1")]
                self.assertEqual(rows, after, table)
            self.assertEqual(con.execute("PRAGMA foreign_key_check").fetchall(), [])
        self.assertTrue(self.store.validate()["passed"])

    def test_reconcile_idempotence_append_only_exports_and_recovery(self):
        self.store.migrate_reconciliation_schema()
        self.store.create_run(run_id="reconcile-test", module="Module 1A", scope="metadata only")
        with self.store.connection() as con:
            original_claim_links = [tuple(r) for r in con.execute("SELECT * FROM claim_evidence ORDER BY 1,2")]
            original_claims = [tuple(r) for r in con.execute("SELECT * FROM claim_versions ORDER BY 1")]
            original_evidence = {r["evidence_span_id"]: dict(r) for r in con.execute("SELECT * FROM evidence_spans")}
            original_reviews = {r["review_id"]: dict(r) for r in con.execute("SELECT * FROM claim_reviews")}
        changes = self.store.reconcile_module1_metadata(
            RUN_DIR, run_id="reconcile-test", verified_manifest=RUN_DIR / "FILE_MANIFEST_RECONCILED.json")
        self.assertEqual(changes, {"source_versions": 12, "entity_versions": 4,
                                   "evidence_spans": 8, "claim_reviews": 12})
        first_hash = logical_inventory(self.db)["logical_sha256"]
        self.assertEqual(self.store.reconcile_module1_metadata(
            RUN_DIR, run_id="reconcile-test", verified_manifest=RUN_DIR / "FILE_MANIFEST_RECONCILED.json"),
            {key: 0 for key in changes})
        self.assertEqual(first_hash, logical_inventory(self.db)["logical_sha256"])
        with self.store.connection() as con:
            self.assertEqual(original_claim_links, [tuple(r) for r in con.execute("SELECT * FROM claim_evidence ORDER BY 1,2")])
            self.assertEqual(original_claims, [tuple(r) for r in con.execute("SELECT * FROM claim_versions ORDER BY 1")])
            for ident, row in original_evidence.items():
                self.assertEqual(row, dict(con.execute("SELECT * FROM evidence_spans WHERE evidence_span_id=?", (ident,)).fetchone()))
            for ident, row in original_reviews.items():
                self.assertEqual(row, dict(con.execute("SELECT * FROM claim_reviews WHERE review_id=?", (ident,)).fetchone()))
            self.assertEqual(con.execute("SELECT count(*) FROM canonical_graph").fetchone()[0], 0)
            self.assertEqual(con.execute("SELECT count(*) FROM current_evidence_spans").fetchone()[0], 12)
            self.assertEqual(con.execute("SELECT count(*) FROM current_claim_reviews WHERE independent=0").fetchone()[0], 12)
            self.assertEqual(con.execute("PRAGMA foreign_key_check").fetchall(), [])
            self.assertEqual(con.execute("SELECT count(*) FROM current_entity_versions WHERE chromosomal_location IS NOT NULL").fetchone()[0], 4)
        self.assertTrue(self.store.validate()["passed"])
        a, b = Path(self.tmp.name) / "export-a", Path(self.tmp.name) / "export-b"
        self.assertEqual(self.store.export(a), self.store.export(b))
        self.assertEqual(len((a / "current_evidence_spans.jsonl").read_text().splitlines()), 12)
        self.assertEqual(len((a / "evidence_spans.jsonl").read_text().splitlines()), 20)
        # SQL recovery preserves the logical database and FK integrity.
        with self.store.connection() as con:
            dump = "\n".join(con.iterdump()) + "\n"
        restored = Path(self.tmp.name) / "restored.db"
        with sqlite3.connect(restored) as con:
            con.executescript(dump)
            self.assertEqual(con.execute("PRAGMA foreign_key_check").fetchall(), [])
        self.assertEqual(logical_inventory(self.db)["logical_sha256"], logical_inventory(restored)["logical_sha256"])
        self.assertTrue(AtlasStore(restored, ROOT / "schema.sql", ROOT).validate()["passed"])

    def test_failure_rolls_back_all_insertions(self):
        self.store.migrate_reconciliation_schema()
        self.store.create_run(run_id="rollback-test", module="Module 1A", scope="metadata only")
        # A late review-provenance conflict forces rollback after source, entity,
        # and evidence inserts have already occurred in the transaction.
        with self.store.connection(write=True) as con:
            old = dict(con.execute("SELECT * FROM claim_reviews ORDER BY review_id LIMIT 1").fetchone())
            old.update(review_id=old["review_id"]+"-v2", version_no=2,
                       supersedes_review_id=old["review_id"], independent=1)
            cols = list(old)
            con.execute(f"INSERT INTO claim_reviews({','.join(cols)}) VALUES({','.join('?' for _ in cols)})",
                        tuple(old[c] for c in cols))
        before = logical_inventory(self.db)["logical_sha256"]
        with self.assertRaisesRegex(ValueError, "Unexpected review provenance"):
            self.store.reconcile_module1_metadata(RUN_DIR, run_id="rollback-test",
                verified_manifest=RUN_DIR / "FILE_MANIFEST_RECONCILED.json")
        self.assertEqual(before, logical_inventory(self.db)["logical_sha256"])

    def test_manifest_cannot_substitute_decoy_files(self):
        self.store.migrate_reconciliation_schema()
        self.store.create_run(run_id="manifest-test", module="Module 1A", scope="metadata only")
        local_root = Path(self.tmp.name)
        run = local_root / "runs" / RUN_DIR.name
        run.mkdir(parents=True)
        manifest = json.loads((RUN_DIR / "FILE_MANIFEST_RECONCILED.json").read_text())
        for item in manifest["files"]:
            source = ROOT / item["path"]
            dest = local_root / item["path"]
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, dest)
            if source.name in ("entities.jsonl", "source_manifest.json", "evidence_spans.jsonl", "verification.jsonl"):
                decoy = local_root / "decoy" / source.name
                decoy.parent.mkdir(exist_ok=True)
                shutil.copyfile(source, decoy)
                item["path"] = decoy.relative_to(local_root).as_posix()
        shutil.copyfile(RUN_DIR / "FILE_MANIFEST.json", run / "FILE_MANIFEST.json")
        historical_outer = local_root / "manifests/RELEASE_MANIFEST_PRE_RECONCILIATION.json"
        historical_outer.parent.mkdir(parents=True)
        shutil.copyfile(ROOT / "manifests/RELEASE_MANIFEST_PRE_RECONCILIATION.json", historical_outer)
        source_manifest = run / "source_manifest.json"
        tampered = json.loads(source_manifest.read_text())
        tampered["database_record_sources"][0]["url"] = "https://example.invalid/unverified"
        source_manifest.write_text(json.dumps(tampered))
        verified = run / "FILE_MANIFEST_RECONCILED.json"
        verified.write_text(json.dumps(manifest))
        local_store = AtlasStore(self.db, ROOT / "schema.sql", local_root)
        before = logical_inventory(self.db)["logical_sha256"]
        with self.assertRaisesRegex(ValueError, "path set differs"):
            local_store.reconcile_module1_metadata(run, run_id="manifest-test", verified_manifest=verified)
        self.assertEqual(before, logical_inventory(self.db)["logical_sha256"])

    def test_manifest_cannot_self_attest_changed_archived_bytes(self):
        self.store.migrate_reconciliation_schema()
        self.store.create_run(run_id="manifest-test", module="Module 1A", scope="metadata only")
        local_root = Path(self.tmp.name)
        run = local_root / "runs" / RUN_DIR.name
        run.mkdir(parents=True)
        manifest = json.loads((RUN_DIR / "FILE_MANIFEST_RECONCILED.json").read_text())
        for item in manifest["files"]:
            dest = local_root / item["path"]
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / item["path"], dest)
        shutil.copyfile(RUN_DIR / "FILE_MANIFEST.json", run / "FILE_MANIFEST.json")
        historical_outer = local_root / "manifests/RELEASE_MANIFEST_PRE_RECONCILIATION.json"
        historical_outer.parent.mkdir(parents=True)
        shutil.copyfile(ROOT / "manifests/RELEASE_MANIFEST_PRE_RECONCILIATION.json", historical_outer)
        store = AtlasStore(self.db, ROOT / "schema.sql", local_root)
        verified = run / "FILE_MANIFEST_RECONCILED.json"
        source = run / "source_manifest.json"
        doc = json.loads(source.read_text())
        doc["database_record_sources"][0]["url"] = "https://example.invalid/unverified"
        source.write_text(json.dumps(doc))
        for item in manifest["files"]:
            if item["path"].endswith("/source_manifest.json"):
                item["sha256"], item["size_bytes"] = sha256_file(source), source.stat().st_size
        manifest["historical_mismatches"] = [
            {"path": item["path"], "historical_record": next(old for old in json.loads(
                (run / "FILE_MANIFEST.json").read_text())["files"] if old["path"] == item["path"]),
             "current_bytes": item} for item in manifest["files"] if item["path"].endswith("/source_manifest.json")]
        verified.write_text(json.dumps(manifest))
        before = logical_inventory(self.db)["logical_sha256"]
        with self.assertRaisesRegex(ValueError, "outer release manifest|mismatch accounting"):
            store.reconcile_module1_metadata(run, run_id="manifest-test", verified_manifest=verified)
        self.assertEqual(before, logical_inventory(self.db)["logical_sha256"])
        # Altering the historical inner manifest is independently rejected.
        shutil.copyfile(RUN_DIR / "source_manifest.json", source)
        old_path = run / "FILE_MANIFEST.json"
        old = json.loads(old_path.read_text())
        for item in old["files"]:
            if item["path"].endswith("/source_manifest.json"):
                item["sha256"], item["size_bytes"] = sha256_file(source), source.stat().st_size
        old_path.write_text(json.dumps(old))
        manifest["supersedes_manifest_sha256"] = sha256_file(old_path)
        verified.write_text(json.dumps(manifest))
        with self.assertRaisesRegex(ValueError, "Historical inner manifest does not match outer"):
            store.reconcile_module1_metadata(run, run_id="manifest-test", verified_manifest=verified)


if __name__ == "__main__": unittest.main()
