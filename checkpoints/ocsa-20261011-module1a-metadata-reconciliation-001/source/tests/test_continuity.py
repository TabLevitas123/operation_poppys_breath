from __future__ import annotations

import hashlib
import importlib.util
import json
import tempfile
import unittest
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


build_release = load_module("ocsa_build_release", ROOT / "scripts/build_release.py")
bootstrap_restore = load_module("ocsa_bootstrap_restore", ROOT / "scripts/bootstrap_restore.py")
continuity_guard = load_module("ocsa_continuity_guard", ROOT / "scripts/continuity_guard.py")
sql_recovery = load_module("ocsa_sql_recovery", ROOT / "scripts/sql_recovery.py")


class OCSAContinuityTests(unittest.TestCase):
    def test_release_selection_includes_all_ordinary_root_files(self):
        selected = {
            path.relative_to(ROOT).as_posix()
            for path in build_release.selected(ROOT)
        }
        for required in (
            "CONTINUITY_CONTRACT.md",
            "LOCAL_FIRST.md",
            "PERSISTENCE.md",
            "README.md",
            "REPOSITORY_NOTES.md",
            "RUN_PROTOCOL.md",
            "requirements.txt",
            "atlas.db",
            "schema.sql",
            "scripts/bootstrap_restore.py",
            "scripts/continuity_guard.py",
        ):
            self.assertIn(required, selected)

    def test_release_selection_excludes_self_referential_pointers(self):
        selected = {
            path.relative_to(ROOT).as_posix()
            for path in build_release.selected(ROOT)
        }
        self.assertNotIn("state/RECOVERY_INDEX.json", selected)
        self.assertNotIn("manifests/CONTINUITY_CHECKPOINT.json", selected)
        self.assertNotIn("OCSA_latest.zip", selected)

    def test_bootstrap_rejects_path_traversal(self):
        with tempfile.TemporaryDirectory() as temporary:
            archive_path = Path(temporary) / "unsafe.zip"
            with zipfile.ZipFile(archive_path, "w") as archive:
                archive.writestr("../escape.txt", "bad")
            destination = Path(temporary) / "extract"
            destination.mkdir()
            with self.assertRaisesRegex(ValueError, "unsafe archive member"):
                bootstrap_restore.safe_extract(archive_path, destination)

    def test_repository_snapshot_hash_is_preserved(self):
        expected = "608dc611ddc80e9ce0979ac0081f6bd87ebca3181cc49831872ec833d9bb9a94"
        directory = ROOT / "legacy/repository-snapshots"
        snapshot = directory / f"operation_poppys_breath-main-{expected}.zip"
        if snapshot.is_file():
            self.assertEqual(continuity_guard.sha256_file(snapshot), expected)
            return
        marker = directory / "GITHUB_RECONSTRUCTION.json"
        self.assertTrue(marker.is_file(), "neither the exact repository ZIP nor a GitHub reconstruction marker exists")
        payload = json.loads(marker.read_text())
        self.assertTrue(payload.get("recovery_mode"))
        self.assertEqual(payload.get("original_zip_sha256"), expected)
        self.assertEqual(payload.get("source_repository"), "TabLevitas123/operation_poppys_breath")
        self.assertRegex(payload.get("source_commit", ""), r"^[0-9a-f]{40}$")

    def test_exact_repository_module1_package_is_present(self):
        run = ROOT / "runs/ocsa-20260725-module1-receptor-identifiers-001"
        self.assertTrue((run / "search_manifest.json").is_file())
        self.assertTrue((run / "verification-report.md").is_file())
        entities = [json.loads(line) for line in (run / "entities.jsonl").read_text().splitlines() if line]
        iuphar = {item["entity_id"]: item for item in entities if item["entity_type"] == "receptor_target"}
        self.assertEqual(iuphar["ENT-IUPHAR-319"]["chromosomal_location"], "6q25.2")
        self.assertIn("KOR-3", iuphar["ENT-IUPHAR-320"]["aliases"])

    def test_full_local_gate_passes(self):
        result = continuity_guard.verify_workspace(ROOT, full=False, verify_archive=False)
        self.assertTrue(result["passed"], result)

    def test_sql_recovery_snapshot_matches_database(self):
        manifest = json.loads((ROOT / "recovery/atlas-sql-manifest.json").read_text())
        current = sql_recovery.logical_inventory(ROOT / "atlas.db")
        self.assertEqual(current["logical_sha256"], manifest["logical_sha256"])
        result = sql_recovery.verify_snapshot(
            ROOT, ROOT / "recovery/atlas.sql", ROOT / "recovery/atlas-sql-manifest.json"
        )
        self.assertTrue(result["passed"], result)


if __name__ == "__main__":
    unittest.main()
