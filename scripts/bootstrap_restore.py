from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import sqlite3
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path, PurePosixPath


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def safe_extract(archive_path: Path, destination: Path) -> dict:
    with zipfile.ZipFile(archive_path) as archive:
        for member in archive.infolist():
            path = PurePosixPath(member.filename)
            if path.is_absolute() or ".." in path.parts:
                raise ValueError(f"unsafe archive member: {member.filename}")
            mode = (member.external_attr >> 16) & 0o170000
            if mode in {0o120000, 0o060000}:
                raise ValueError(f"link or device rejected: {member.filename}")
        bad = archive.testzip()
        if bad:
            raise ValueError(f"ZIP CRC failure: {bad}")
        archive.extractall(destination)

    manifest_path = destination / "release-manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    errors = []
    for record in manifest["files"]:
        target = destination / record["path"]
        if not target.is_file():
            errors.append(f"missing {record['path']}")
        elif target.stat().st_size != record["size_bytes"]:
            errors.append(f"size mismatch {record['path']}")
        elif sha256_file(target) != record["sha256"]:
            errors.append(f"hash mismatch {record['path']}")
    database = destination / "atlas.db"
    if sha256_file(database) != manifest["database_sha256"]:
        errors.append("database hash mismatch")
    if errors:
        raise ValueError("; ".join(errors))

    connection = sqlite3.connect(f"file:{database}?mode=ro", uri=True)
    try:
        quick = connection.execute("PRAGMA quick_check").fetchall()
        foreign = connection.execute("PRAGMA foreign_key_check").fetchall()
    finally:
        connection.close()
    if quick != [("ok",)] or foreign:
        raise ValueError(f"SQLite checks failed: quick={quick!r}, foreign={foreign!r}")

    validate = subprocess.run(
        [sys.executable, "src/ocsa_store.py", "--db", "atlas.db", "--schema", "schema.sql", "--root", ".", "validate"],
        cwd=destination,
        text=True,
        capture_output=True,
    )
    if validate.returncode:
        raise ValueError("OCSA validation failed: " + validate.stdout + validate.stderr)
    tests = subprocess.run(
        [sys.executable, "-m", "unittest", "discover", "-s", "tests", "-v"],
        cwd=destination,
        text=True,
        capture_output=True,
    )
    if tests.returncode:
        raise ValueError("restored tests failed: " + tests.stdout + tests.stderr)
    return {
        "database_sha256": sha256_file(database),
        "validation_stdout": validate.stdout,
        "tests_stdout": tests.stdout,
        "tests_stderr": tests.stderr,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Atomically restore a verified OCSA archive")
    parser.add_argument("archive", type=Path)
    parser.add_argument("--target", type=Path, default=Path("/mnt/data/operation_poppys_breath"))
    parser.add_argument("--expected-archive-sha256")
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()

    archive = args.archive.resolve()
    target = args.target.resolve()
    archive_hash = sha256_file(archive)
    if args.expected_archive_sha256 and archive_hash != args.expected_archive_sha256:
        raise SystemExit("archive SHA-256 does not match recovery index")

    target.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=target.parent, prefix="ocsa-restore-") as temp:
        staged = Path(temp) / "workspace"
        staged.mkdir()
        verification = safe_extract(archive, staged)

        if target.exists():
            guard = target / "scripts/continuity_guard.py"
            if guard.is_file() and not args.force:
                check = subprocess.run(
                    [sys.executable, str(guard), "--root", str(target), "verify", "--full"],
                    text=True,
                    capture_output=True,
                )
                if check.returncode == 0:
                    raise SystemExit("target already contains a valid workspace; refusing to overwrite without --force")
            backup = target.with_name(target.name + ".pre-restore-backup")
            if backup.exists():
                shutil.rmtree(backup)
            os.replace(target, backup)
        os.replace(staged, target)

    result = {
        "passed": True,
        "archive": str(archive),
        "archive_sha256": archive_hash,
        "target": str(target),
        **verification,
    }
    print(json.dumps(result, sort_keys=True, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
