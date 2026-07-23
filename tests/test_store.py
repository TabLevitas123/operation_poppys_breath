import sqlite3
import tempfile
import unittest
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))

from ocsa_store import AtlasStore


class AtlasStoreTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        self.store = AtlasStore(self.root / "atlas.db", ROOT / "schema.sql")
        self.store.init()

    def tearDown(self):
        self.tempdir.cleanup()

    def test_initialization_and_validation(self):
        self.assertEqual(self.store.validate(), [])
        stats = self.store.stats()
        self.assertEqual(stats["metadata"]["schema_version"], "0.1.0")
        self.assertEqual(stats["tables"]["claims"], 0)

    def test_invalid_claim_object_is_rejected_by_schema(self):
        con = self.store.connect()
        now = "2026-07-23T00:00:00+00:00"
        con.execute(
            "INSERT INTO sources(id,title,source_type,created_at,updated_at) VALUES(?,?,?,?,?)",
            ("src_test", "Test", "fixture", now, now),
        )
        con.execute(
            "INSERT INTO entities(id,canonical_name,entity_type,created_at,updated_at) VALUES(?,?,?,?,?)",
            ("ent_test", "Test receptor", "receptor", now, now),
        )
        with self.assertRaises(sqlite3.IntegrityError):
            con.execute(
                """
                INSERT INTO claims(
                    id,subject_entity_id,predicate,source_id,source_locator,
                    created_at,updated_at
                ) VALUES(?,?,?,?,?,?,?)
                """,
                ("clm_bad", "ent_test", "ACTIVATES", "src_test", "fixture", now, now),
            )


if __name__ == "__main__":
    unittest.main(verbosity=2)
