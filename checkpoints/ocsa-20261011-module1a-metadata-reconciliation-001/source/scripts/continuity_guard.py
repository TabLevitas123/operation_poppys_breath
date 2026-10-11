from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import sqlite3
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

REQUIRED_PATHS = (
    "atlas.db",
    "schema.sql",
    "src/ocsa_store.py",
    "tests/test_store.py",
    "state/WORKSPACE_STATE.json",
    "manifests/FINAL_CHECKPOINT.json",
    "scripts/build_release.py",
    "scripts/verify_release.py",
    "scripts/sql_recovery.py",
    "recovery/atlas.sql",
    "recovery/atlas-sql-manifest.json",
)

EXTERNAL_POINTERS = (
    "state/RECOVERY_INDEX.json",
    "manifests/CONTINUITY_CHECKPOINT.json",
)


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def run(cmd: list[str], cwd: Path) -> dict:
    proc = subprocess.run(cmd, cwd=cwd, text=True, capture_output=True)
    return {
        "command": cmd,
        "returncode": proc.returncode,
        "stdout": proc.stdout,
        "stderr": proc.stderr,
    }


def database_checks(path: Path) -> list[str]:
    errors: list[str] = []
    try:
        connection = sqlite3.connect(f"file:{path}?mode=ro", uri=True)
        try:
            quick = connection.execute("PRAGMA quick_check").fetchall()
            if quick != [("ok",)]:
                errors.append(f"SQLite quick_check failed: {quick!r}")
            foreign = connection.execute("PRAGMA foreign_key_check").fetchall()
            if foreign:
                errors.append(f"SQLite foreign_key_check returned {len(foreign)} row(s)")
        finally:
            connection.close()
    except Exception as exc:
        errors.append(f"Unable to open database read-only: {exc}")
    return errors


def verify_workspace(root: Path, full: bool, verify_archive: bool) -> dict:
    root = root.resolve()
    errors: list[str] = []
    warnings: list[str] = []
    details: dict = {}

    for rel in REQUIRED_PATHS:
        if not (root / rel).is_file():
            errors.append(f"missing required file: {rel}")

    state = {}
    checkpoint = {}
    recovery_index = {}
    try:
        state = json.loads((root / "state/WORKSPACE_STATE.json").read_text(encoding="utf-8"))
    except Exception as exc:
        errors.append(f"invalid WORKSPACE_STATE.json: {exc}")
    try:
        checkpoint = json.loads((root / "manifests/FINAL_CHECKPOINT.json").read_text(encoding="utf-8"))
    except Exception as exc:
        errors.append(f"invalid FINAL_CHECKPOINT.json: {exc}")
    if (root / "state/RECOVERY_INDEX.json").is_file():
        try:
            recovery_index = json.loads((root / "state/RECOVERY_INDEX.json").read_text(encoding="utf-8"))
        except Exception as exc:
            errors.append(f"invalid RECOVERY_INDEX.json: {exc}")
    else:
        warnings.append("state/RECOVERY_INDEX.json is absent; durable alias lookup is unavailable")

    database = root / "atlas.db"
    if database.is_file():
        database_hash = sha256_file(database)
        details["database_sha256"] = database_hash
        expected_hashes = {
            value
            for value in (
                state.get("database_sha256"),
                checkpoint.get("database", {}).get("sha256"),
                recovery_index.get("database", {}).get("sha256"),
            )
            if value
        }
        if len(expected_hashes) > 1:
            errors.append(f"conflicting recorded database hashes: {sorted(expected_hashes)}")
        if expected_hashes and database_hash not in expected_hashes:
            errors.append("atlas.db SHA-256 does not match the recorded checkpoint")
        errors.extend(database_checks(database))

    if not errors or database.is_file():
        validation = run(
            [sys.executable, "src/ocsa_store.py", "--db", "atlas.db", "--schema", "schema.sql", "--root", ".", "validate"],
            root,
        )
        details["validation"] = validation
        if validation["returncode"] != 0:
            errors.append("OCSA validation failed")

    if full:
        tests = run([sys.executable, "-m", "unittest", "discover", "-s", "tests", "-v"], root)
        details["tests"] = tests
        if tests["returncode"] != 0:
            errors.append("automated tests failed")

    if verify_archive:
        archive = root / "OCSA_latest.zip"
        if not archive.is_file():
            errors.append("OCSA_latest.zip is missing")
        else:
            details["archive_sha256"] = sha256_file(archive)
            archive_result = run(
                [sys.executable, "scripts/verify_release.py", str(archive)], root
            )
            details["archive_verification"] = archive_result
            if archive_result["returncode"] != 0:
                errors.append("latest release archive failed clean-restoration verification")
            recorded = recovery_index.get("archive", {}).get("sha256")
            if recorded and details["archive_sha256"] != recorded:
                errors.append("OCSA_latest.zip SHA-256 does not match RECOVERY_INDEX.json")

    return {
        "checked_at": utc_now(),
        "root": str(root),
        "passed": not errors,
        "full": full,
        "archive_checked": verify_archive,
        "errors": errors,
        "warnings": warnings,
        "details": details,
    }


def write_json(path: Path, value: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(value, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    os.replace(temporary, path)


def checkpoint(root: Path, run_id: str, release_version: str) -> dict:
    root = root.resolve()
    basic_preflight = verify_workspace(root, full=False, verify_archive=False)
    if not basic_preflight["passed"]:
        return {"passed": False, "stage": "basic_preflight", "preflight": basic_preflight}

    # Flush WAL content before exporting the canonical text recovery snapshot.
    connection = sqlite3.connect(root / "atlas.db")
    try:
        connection.execute("PRAGMA wal_checkpoint(TRUNCATE)").fetchall()
        connection.commit()
    finally:
        connection.close()

    sql_export = run([sys.executable, "scripts/sql_recovery.py", "--root", str(root), "export"], root)
    if sql_export["returncode"] != 0:
        return {"passed": False, "stage": "sql_recovery_export", "result": sql_export}
    sql_verify = run([sys.executable, "scripts/sql_recovery.py", "--root", str(root), "verify"], root)
    if sql_verify["returncode"] != 0:
        return {"passed": False, "stage": "sql_recovery_verification", "result": sql_verify}

    preflight = verify_workspace(root, full=True, verify_archive=False)
    if not preflight["passed"]:
        return {"passed": False, "stage": "full_preflight", "preflight": preflight}
    test_output = preflight.get("details", {}).get("tests", {}).get("stderr", "")
    match = re.search(r"Ran (\d+) tests?", test_output)
    test_count = int(match.group(1)) if match else None

    database_hash = sha256_file(root / "atlas.db")
    sql_manifest = json.loads((root / "recovery/atlas-sql-manifest.json").read_text(encoding="utf-8"))
    state_path = root / "state/WORKSPACE_STATE.json"
    state = json.loads(state_path.read_text(encoding="utf-8"))
    state.update(
        {
            "active_checkpoint_id": run_id,
            "database_sha256": database_hash,
            "last_local_verification": utc_now(),
            "recovery_index_path": "state/RECOVERY_INDEX.json",
            "release_version": release_version,
            "automated_tests_passed": test_count,
            "workspace_status": "verified_checkpoint_content_finalized",
        }
    )
    # Archive hashes live only in the external recovery index to avoid self-reference.
    for key in (
        "base_release_archive_sha256",
        "final_release_archive_sha256",
        "final_release_archive_size_bytes",
    ):
        state.pop(key, None)
    write_json(state_path, state)

    content_manifest = {
        "manifest_version": "1.0",
        "run_id": run_id,
        "release_version": release_version,
        "created_at": utc_now(),
        "database": {
            "path": "atlas.db",
            "sha256": database_hash,
            "size_bytes": (root / "atlas.db").stat().st_size,
        },
        "archive_hash_location": "external state/RECOVERY_INDEX.json",
        "sql_recovery": {
            "path": "recovery/atlas.sql",
            "manifest_path": "recovery/atlas-sql-manifest.json",
            "sql_sha256": sql_manifest["sql_sha256"],
            "logical_sha256": sql_manifest["logical_sha256"],
            "verified": True,
        },
        "scientific_state": {
            "accepted_claims": state.get("canonical_claims", 0),
            "provisional_claims": state.get("provisional_claims", 0),
            "entities": state.get("entities", 0),
            "evidence_spans": state.get("evidence_spans", 0),
        },
    }
    write_json(root / "manifests/CHECKPOINT_CONTENT.json", content_manifest)
    final_checkpoint = {
        "checkpoint_id": run_id,
        "release_version": release_version,
        "created_at": utc_now(),
        "database": content_manifest["database"],
        "archive": {
            "sha256_location": "state/RECOVERY_INDEX.json",
            "clean_restore_verification_required": True,
        },
        "tests": {"passed": True, "count": test_count},
        "validation": {"passed": True, "blocking_count": 0, "warning_count": 0},
        "scientific_state": content_manifest["scientific_state"],
        "repository_snapshot_sha256": state.get("repository_snapshot_sha256"),
        "database_metadata_reconciliation_pending": state.get("database_metadata_reconciliation_pending", False),
    }
    write_json(root / "manifests/FINAL_CHECKPOINT.json", final_checkpoint)

    out_dir = root / "releases" / release_version
    out_dir.mkdir(parents=True, exist_ok=True)
    versioned_archive = out_dir / f"OCSA_{release_version}_{run_id}.zip"
    build = run(
        [sys.executable, "scripts/build_release.py", "--root", str(root), "--output", str(versioned_archive), "--run-id", run_id, "--release-version", release_version],
        root,
    )
    if build["returncode"] != 0:
        return {"passed": False, "stage": "build", "build": build}

    verification_path = root / "reports" / f"{run_id}-clean-restore-verification.json"
    verify = run(
        [sys.executable, "scripts/verify_release.py", str(versioned_archive), "--output", str(verification_path)],
        root,
    )
    if verify["returncode"] != 0:
        return {"passed": False, "stage": "clean_restore_verification", "verification": verify}

    latest = root / "OCSA_latest.zip"
    shutil.copyfile(versioned_archive, latest)
    archive_hash = sha256_file(latest)
    archive_size = latest.stat().st_size

    external = {
        "index_version": "1.0",
        "checkpoint_id": run_id,
        "release_version": release_version,
        "created_at": utc_now(),
        "local_workspace": str(root),
        "archive": {
            "local_path": "OCSA_latest.zip",
            "versioned_local_path": versioned_archive.relative_to(root).as_posix(),
            "sha256": archive_hash,
            "size_bytes": archive_size,
            "clean_restore_verified": True,
            "library_stable_path": "/Operation_Poppys_Breath/OCSA_LATEST.zip",
            "library_versioned_path": f"/Operation_Poppys_Breath/checkpoints/{run_id}.zip",
            "library_file_id": None,
            "library_versioned_file_id": None,
        },
        "database": {
            "local_path": "atlas.db",
            "sha256": database_hash,
            "size_bytes": (root / "atlas.db").stat().st_size,
            "library_stable_path": "/Operation_Poppys_Breath/atlas_latest.db",
            "library_versioned_path": f"/Operation_Poppys_Breath/checkpoints/{run_id}.db",
            "library_file_id": None,
            "library_versioned_file_id": None,
        },
        "sql_recovery": {
            "github_sql_path": "recovery/atlas.sql",
            "github_manifest_path": "recovery/atlas-sql-manifest.json",
            "sql_sha256": sql_manifest["sql_sha256"],
            "logical_sha256": sql_manifest["logical_sha256"],
            "verified": True,
        },
        "bootstrap": {
            "library_path": "/Operation_Poppys_Breath/BOOTSTRAP_RESTORE.py",
            "github_path": "scripts/bootstrap_restore.py",
        },
        "github": {
            "repository": "TabLevitas123/operation_poppys_breath",
            "branch": "main",
            "commit": None,
        },
        "durable_upload_complete": False,
    }
    write_json(root / "state/RECOVERY_INDEX.json", external)
    write_json(root / "manifests/CONTINUITY_CHECKPOINT.json", external)

    final_check = verify_workspace(root, full=True, verify_archive=True)
    if not final_check["passed"]:
        return {"passed": False, "stage": "postbuild_local_gate", "verification": final_check}

    return {
        "passed": True,
        "run_id": run_id,
        "release_version": release_version,
        "archive": str(latest),
        "archive_sha256": archive_hash,
        "archive_size_bytes": archive_size,
        "versioned_archive": str(versioned_archive),
        "database": str(root / "atlas.db"),
        "database_sha256": database_hash,
        "recovery_index": str(root / "state/RECOVERY_INDEX.json"),
        "verification_report": str(verification_path),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Fail-closed OCSA continuity guard")
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    sub = parser.add_subparsers(dest="command", required=True)

    verify = sub.add_parser("verify")
    verify.add_argument("--full", action="store_true")
    verify.add_argument("--archive", action="store_true")
    verify.add_argument("--result-output", type=Path)

    create = sub.add_parser("checkpoint")
    create.add_argument("--run-id", required=True)
    create.add_argument("--release-version", required=True)
    create.add_argument("--result-output", type=Path)

    args = parser.parse_args()
    if args.command == "verify":
        result = verify_workspace(args.root, full=args.full, verify_archive=args.archive)
    else:
        result = checkpoint(args.root, args.run_id, args.release_version)

    if args.result_output:
        write_json(args.result_output, result)
    print(json.dumps(result, sort_keys=True, indent=2))
    return 0 if result.get("passed") else 1


if __name__ == "__main__":
    raise SystemExit(main())
