from __future__ import annotations

import argparse
import hashlib
import json
import zipfile
from pathlib import Path

FIXED_TIMESTAMP = (2026, 7, 25, 12, 0, 0)
INCLUDE_DIRECTORIES = {
    ".github",
    "changesets",
    "checkpoints",
    "exports",
    "legacy",
    "manifests",
    "reports",
    "recovery",
    "runs",
    "scripts",
    "snapshots",
    "src",
    "state",
    "tests",
}
EXCLUDE_PREFIXES = (
    ".git/",
    "releases/",
    "manifests/release-manifest.json",
    "manifests/CONTINUITY_CHECKPOINT.json",
    "state/RECOVERY_INDEX.json",
    "__pycache__/",
)
EXCLUDE_ROOT_FILES = {
    "OCSA_latest.zip",
}
EXCLUDE_SUFFIXES = (
    ".pyc",
    ".db-wal",
    ".db-shm",
    ".db-journal",
    ".tmp",
    ".partial",
)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def selected(root: Path) -> list[Path]:
    selected_files: list[Path] = []
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        relative = path.relative_to(root).as_posix()
        parts = relative.split("/")
        if any(relative == prefix.rstrip("/") or relative.startswith(prefix) for prefix in EXCLUDE_PREFIXES):
            continue
        if relative in EXCLUDE_ROOT_FILES or relative.endswith(EXCLUDE_SUFFIXES):
            continue
        if "/__pycache__/" in "/" + relative:
            continue
        if len(parts) == 1:
            selected_files.append(path)
        elif parts[0] in INCLUDE_DIRECTORIES:
            if parts[0] == "reports" and ("build-result" in relative or "restore-report" in relative):
                continue
            selected_files.append(path)
    return sorted(selected_files, key=lambda item: item.relative_to(root).as_posix())


def main() -> int:
    parser = argparse.ArgumentParser(description="Build a deterministic complete OCSA release archive")
    parser.add_argument("--root", type=Path, default=Path("."))
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--run-id", required=True)
    parser.add_argument("--release-version", required=True)
    args = parser.parse_args()

    root = args.root.resolve()
    output = args.output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    files = selected(root)

    manifest = {
        "manifest_version": "1.0",
        "run_id": args.run_id,
        "release_version": args.release_version,
        "database_sha256": sha256_file(root / "atlas.db"),
        "files": [
            {
                "path": path.relative_to(root).as_posix(),
                "size_bytes": path.stat().st_size,
                "sha256": sha256_file(path),
            }
            for path in files
        ],
    }
    manifest_bytes = (json.dumps(manifest, sort_keys=True, indent=2) + "\n").encode("utf-8")
    manifest_path = output.parent / "release-manifest.json"
    manifest_path.write_bytes(manifest_bytes)

    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in files:
            relative = path.relative_to(root).as_posix()
            info = zipfile.ZipInfo(relative, FIXED_TIMESTAMP)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, path.read_bytes(), compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)
        info = zipfile.ZipInfo("release-manifest.json", FIXED_TIMESTAMP)
        info.compress_type = zipfile.ZIP_DEFLATED
        info.external_attr = 0o100644 << 16
        archive.writestr(info, manifest_bytes, compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)

    result = {
        "archive_path": str(output),
        "archive_sha256": sha256_file(output),
        "archive_size_bytes": output.stat().st_size,
        "manifest_path": str(manifest_path),
        "manifest_sha256": sha256_file(manifest_path),
        "database_sha256": manifest["database_sha256"],
        "file_count": len(files),
        "run_id": args.run_id,
        "release_version": args.release_version,
    }
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
