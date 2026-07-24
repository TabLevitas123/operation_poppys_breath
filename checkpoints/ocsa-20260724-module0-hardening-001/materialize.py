from __future__ import annotations

import argparse
import base64
import hashlib
import json
import os
import zipfile
from pathlib import Path, PurePosixPath


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def safe_members(archive: zipfile.ZipFile) -> list[zipfile.ZipInfo]:
    members = archive.infolist()
    for member in members:
        path = PurePosixPath(member.filename)
        if path.is_absolute() or ".." in path.parts:
            raise ValueError(f"unsafe archive path: {member.filename}")
        mode = (member.external_attr >> 16) & 0o170000
        if mode in {0o120000, 0o060000}:
            raise ValueError(f"archive link or device rejected: {member.filename}")
    return members


def main() -> int:
    parser = argparse.ArgumentParser(description="Restore the authenticated OCSA Module 0 checkpoint")
    parser.add_argument("--checkpoint", type=Path, default=Path(__file__).resolve().parent)
    parser.add_argument("--archive-output", type=Path)
    parser.add_argument("--extract-output", type=Path)
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()

    checkpoint = args.checkpoint.resolve()
    manifest = json.loads((checkpoint / "manifest.json").read_text(encoding="utf-8"))
    encoded = bytearray()
    for record in manifest["parts"]:
        part = checkpoint / record["path"]
        if not part.is_file():
            raise FileNotFoundError(part)
        if part.stat().st_size != record["size_bytes"]:
            raise ValueError(f"part size mismatch: {record['path']}")
        if sha256_file(part) != record["sha256"]:
            raise ValueError(f"part hash mismatch: {record['path']}")
        encoded.extend(part.read_bytes())

    payload = base64.b64decode(b"".join(bytes(encoded).split()), validate=True)
    archive_record = manifest["archive"]
    if len(payload) != archive_record["size_bytes"]:
        raise ValueError("decoded archive size mismatch")
    archive_hash = hashlib.sha256(payload).hexdigest()
    if archive_hash != archive_record["sha256"]:
        raise ValueError("decoded archive hash mismatch")

    archive_output = args.archive_output or checkpoint / archive_record["filename"]
    archive_output = archive_output.resolve()
    if archive_output.exists() and not args.force:
        if archive_output.stat().st_size != archive_record["size_bytes"] or sha256_file(archive_output) != archive_record["sha256"]:
            raise FileExistsError(f"refusing to replace different archive: {archive_output}")
    else:
        archive_output.parent.mkdir(parents=True, exist_ok=True)
        temporary = archive_output.with_suffix(archive_output.suffix + ".tmp")
        temporary.write_bytes(payload)
        os.replace(temporary, archive_output)

    extract_output = args.extract_output
    if extract_output:
        extract_output = extract_output.resolve()
        if extract_output.exists() and any(extract_output.iterdir()) and not args.force:
            raise FileExistsError(f"extract output is not empty: {extract_output}")
        extract_output.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(archive_output) as archive:
            members = safe_members(archive)
            bad_member = archive.testzip()
            if bad_member:
                raise ValueError(f"ZIP CRC failure: {bad_member}")
            archive.extractall(extract_output, members=members)
            release_manifest = json.loads((extract_output / "release-manifest.json").read_text(encoding="utf-8"))
            for record in release_manifest["files"]:
                target = extract_output / record["path"]
                if not target.is_file():
                    raise FileNotFoundError(record["path"])
                if target.stat().st_size != record["size_bytes"] or sha256_file(target) != record["sha256"]:
                    raise ValueError(f"restored file mismatch: {record['path']}")

    print(json.dumps({
        "passed": True,
        "archive": str(archive_output),
        "archive_sha256": archive_hash,
        "release_version": manifest["release_version"],
        "run_id": manifest["run_id"],
        "extracted_to": str(extract_output) if extract_output else None
    }, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
