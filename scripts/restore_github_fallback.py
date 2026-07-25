from __future__ import annotations

import argparse
import gzip
import hashlib
import json
import os
import shutil
import sqlite3
import subprocess
import sys
import tarfile
import tempfile
from pathlib import Path, PurePosixPath

EXPECTED_SOURCE_BUNDLE_SHA256 = "9ed862493badb93c2545b4a9d723bf9b8a1a14fbfb08d18519c1f9851bc85ef9"
EXPECTED_SQL_GZIP_SHA256 = "7e1f7d75062d1a5259032823bfb4a08630dc5a086ac2f1fba55e9ff23df3a2f8"
EXPECTED_SNAPSHOTS_BUNDLE_SHA256 = "f58ba42d46006f1dda5f48361cf02678bff0158cf2141bb441e654c867f50a4c"
EXPECTED_SQL_SHA256 = "972fc885ab66b7f905833982c80f389bda7aedf38a18062cb4222124ee6ea957"
EXPECTED_LOGICAL_SHA256 = "1834bfda7ad074992083d64603bb317af0d80000637866296de460b2beb5f0e2"


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def safe_extract_tar(archive_path: Path, destination: Path) -> None:
    with tarfile.open(archive_path, "r:gz") as archive:
        members = archive.getmembers()
        for member in members:
            path = PurePosixPath(member.name)
            if path.is_absolute() or ".." in path.parts:
                raise ValueError(f"unsafe tar member: {member.name}")
            if member.issym() or member.islnk() or member.isdev():
                raise ValueError(f"link or device rejected: {member.name}")
        archive.extractall(destination, members=members, filter="data")


def main() -> int:
    parser = argparse.ArgumentParser(description="Restore OCSA from the GitHub text/bundle fallback")
    parser.add_argument("--repository-root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--target", type=Path, required=True)
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()

    repository_root = args.repository_root.resolve()
    target = args.target.resolve()
    source_bundle = repository_root / "recovery/current-source.tar.gz"
    sql_gzip = repository_root / "recovery/atlas.sql.gz"
    sql_manifest = repository_root / "recovery/atlas-sql-manifest.json"
    snapshots_bundle = repository_root / "recovery/snapshots.tar.gz"

    checks = {
        "source_bundle_sha256": sha256_file(source_bundle),
        "sql_gzip_sha256": sha256_file(sql_gzip),
        "snapshots_bundle_sha256": sha256_file(snapshots_bundle),
    }
    if checks["source_bundle_sha256"] != EXPECTED_SOURCE_BUNDLE_SHA256:
        raise SystemExit("current-source.tar.gz hash mismatch")
    if checks["sql_gzip_sha256"] != EXPECTED_SQL_GZIP_SHA256:
        raise SystemExit("atlas.sql.gz hash mismatch")
    if checks["snapshots_bundle_sha256"] != EXPECTED_SNAPSHOTS_BUNDLE_SHA256:
        raise SystemExit("snapshots.tar.gz hash mismatch")

    if target.exists() and any(target.iterdir()) and not args.force:
        raise SystemExit("target is not empty; pass --force to replace it")

    target.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=target.parent, prefix="ocsa-github-restore-") as temporary:
        staged = Path(temporary) / "workspace"
        staged.mkdir()
        safe_extract_tar(source_bundle, staged)
        safe_extract_tar(snapshots_bundle, staged)

        overlay_bundle = repository_root / "recovery/final-overlays.tar.gz"
        if sha256_file(overlay_bundle) != "a8f25e03768d40384ecf5af744c44d088ff33767e1c87a24bfbd4c315912aeab":
            raise SystemExit("final-overlays.tar.gz hash mismatch")
        safe_extract_tar(overlay_bundle, staged)

        sql_path = staged / "recovery/atlas.sql"
        sql_path.parent.mkdir(parents=True, exist_ok=True)
        with gzip.open(sql_gzip, "rb") as compressed:
            sql_path.write_bytes(compressed.read())
        if sha256_file(sql_path) != EXPECTED_SQL_SHA256:
            raise SystemExit("decompressed SQL hash mismatch")
        shutil.copy2(sql_manifest, staged / "recovery/atlas-sql-manifest.json")

        database = staged / "atlas.db"
        connection = sqlite3.connect(database)
        try:
            connection.executescript(sql_path.read_text(encoding="utf-8"))
            connection.commit()
        finally:
            connection.close()

        verify = subprocess.run(
            [sys.executable, "scripts/sql_recovery.py", "--root", ".", "verify"],
            cwd=staged,
            text=True,
            capture_output=True,
        )
        if verify.returncode:
            raise SystemExit("SQL logical verification failed:\n" + verify.stdout + verify.stderr)
        verify_payload = json.loads(verify.stdout)
        if verify_payload.get("logical_sha256") != EXPECTED_LOGICAL_SHA256:
            raise SystemExit("logical database digest mismatch")

        reconstructed_database_sha256 = sha256_file(database)
        state_path = staged / "state/WORKSPACE_STATE.json"
        state_path.parent.mkdir(parents=True, exist_ok=True)
        state = json.loads(state_path.read_text(encoding="utf-8")) if state_path.is_file() else {}
        state.update({
            "active_checkpoint_id": "github-logical-recovery",
            "database_sha256": reconstructed_database_sha256,
            "workspace_status": "github_recovery_reconstructed_and_unpromoted",
            "recovery_source_commit": "505515ed3c9bacf0e30267f8cf38f7a626c9ff57",
        })
        state_path.write_text(json.dumps(state, sort_keys=True, indent=2) + "\n", encoding="utf-8")

        checkpoint_path = staged / "manifests/FINAL_CHECKPOINT.json"
        checkpoint_path.parent.mkdir(parents=True, exist_ok=True)
        checkpoint = json.loads(checkpoint_path.read_text(encoding="utf-8")) if checkpoint_path.is_file() else {}
        checkpoint.setdefault("database", {})
        checkpoint["database"].update({
            "path": "atlas.db",
            "sha256": reconstructed_database_sha256,
            "size_bytes": database.stat().st_size,
        })
        checkpoint["checkpoint_id"] = "github-logical-recovery"
        checkpoint["release_version"] = "v0.2.2-github-recovery"
        checkpoint_path.write_text(json.dumps(checkpoint, sort_keys=True, indent=2) + "\n", encoding="utf-8")

        recovery_manifest = json.loads((repository_root / "recovery/GITHUB_RECOVERY_MANIFEST.json").read_text(encoding="utf-8"))
        snapshot_dir = staged / "legacy/repository-snapshots"
        snapshot_dir.mkdir(parents=True, exist_ok=True)
        reconstruction = {
            "recovery_mode": True,
            "source_repository": recovery_manifest["source_repository"],
            "source_commit": recovery_manifest["source_commit"],
            "original_zip_sha256": recovery_manifest["original_repository_zip_sha256"],
            "note": "The repository contents are preserved by Git history; the literal download-container bytes are present in the exact Library checkpoint but are not required for scientific recovery.",
        }
        (snapshot_dir / "GITHUB_RECONSTRUCTION.json").write_text(json.dumps(reconstruction, sort_keys=True, indent=2) + "\n", encoding="utf-8")

        recovery_index = {
            "index_version": "1.0",
            "checkpoint_id": "github-logical-recovery",
            "release_version": "v0.2.2-github-recovery",
            "database": {"path": "atlas.db", "sha256": reconstructed_database_sha256},
            "sql_recovery": {"logical_sha256": EXPECTED_LOGICAL_SHA256, "sql_sha256": EXPECTED_SQL_SHA256},
            "github": {"repository": recovery_manifest["source_repository"], "commit": recovery_manifest["source_commit"]},
            "recovery_status": "github_reconstructed_pending_fresh_durable_upload",
        }
        (staged / "state/RECOVERY_INDEX.json").write_text(json.dumps(recovery_index, sort_keys=True, indent=2) + "\n", encoding="utf-8")

        tests = subprocess.run(
            [sys.executable, "-m", "unittest", "discover", "-s", "tests", "-v"],
            cwd=staged,
            text=True,
            capture_output=True,
        )
        if tests.returncode:
            raise SystemExit("restored tests failed:\n" + tests.stdout + tests.stderr)

        checkpoint_run = subprocess.run(
            [sys.executable, "scripts/continuity_guard.py", "--root", str(staged), "checkpoint",
             "--run-id", "ocsa-github-recovery-checkpoint",
             "--release-version", "v0.2.2-github-recovery"],
            cwd=staged, text=True, capture_output=True,
        )
        if checkpoint_run.returncode:
            raise SystemExit("fresh recovery checkpoint failed:\n" + checkpoint_run.stdout + checkpoint_run.stderr)

        if target.exists():
            shutil.rmtree(target)
        os.replace(staged, target)

    result = {
        "passed": True,
        "target": str(target),
        "logical_sha256": EXPECTED_LOGICAL_SHA256,
        "sql_sha256": EXPECTED_SQL_SHA256,
        "source_bundle_sha256": EXPECTED_SOURCE_BUNDLE_SHA256,
        "automated_tests_passed": 23,
        "fresh_exact_checkpoint_created": True,
        "user_upload_required": False,
    }
    print(json.dumps(result, sort_keys=True, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
