from __future__ import annotations

import argparse
import base64
import hashlib
import json
import sqlite3
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def normalize_value(value: Any) -> Any:
    if isinstance(value, bytes):
        return {"__blob_base64__": base64.b64encode(value).decode("ascii")}
    if isinstance(value, float):
        return {"__float_repr__": repr(value)}
    return value


def quote_identifier(identifier: str) -> str:
    return '"' + identifier.replace('"', '""') + '"'


def logical_inventory(database: Path) -> dict:
    connection = sqlite3.connect(f"file:{database.resolve()}?mode=ro", uri=True)
    try:
        tables = [row[0] for row in connection.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name")]
        digest = hashlib.sha256()
        counts: dict[str, int] = {}
        table_hashes: dict[str, str] = {}
        for table in tables:
            columns = [row[1] for row in connection.execute(f"PRAGMA table_info({quote_identifier(table)})")]
            rows = connection.execute(f"SELECT * FROM {quote_identifier(table)}").fetchall()
            encoded_rows = [json.dumps([normalize_value(value) for value in row], ensure_ascii=False, sort_keys=True, separators=(",", ":")) for row in rows]
            encoded_rows.sort()
            table_digest = hashlib.sha256()
            header = json.dumps({"table": table, "columns": columns}, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
            table_digest.update(header.encode("utf-8")); table_digest.update(b"\n")
            for encoded in encoded_rows:
                table_digest.update(encoded.encode("utf-8")); table_digest.update(b"\n")
            value = table_digest.hexdigest()
            counts[table] = len(rows); table_hashes[table] = value
            digest.update(table.encode("utf-8")); digest.update(b"\0"); digest.update(value.encode("ascii")); digest.update(b"\n")
        return {"logical_sha256": digest.hexdigest(), "table_counts": counts, "table_sha256": table_hashes}
    finally:
        connection.close()


def export_snapshot(root: Path, sql_path: Path, manifest_path: Path) -> dict:
    root = root.resolve(); database = root / "atlas.db"
    connection = sqlite3.connect(database)
    try:
        connection.execute("PRAGMA wal_checkpoint(TRUNCATE)").fetchall(); connection.commit(); dump = "\n".join(connection.iterdump()) + "\n"
    finally:
        connection.close()
    sql_path.parent.mkdir(parents=True, exist_ok=True); sql_path.write_text(dump, encoding="utf-8")
    inventory = logical_inventory(database)
    manifest = {"manifest_version":"1.0","generated_at":utc_now(),"database_path":"atlas.db","database_physical_sha256":sha256_file(database),"database_size_bytes":database.stat().st_size,"sql_path":sql_path.relative_to(root).as_posix(),"sql_sha256":sha256_file(sql_path),"sql_size_bytes":sql_path.stat().st_size,**inventory}
    manifest_path.parent.mkdir(parents=True, exist_ok=True); manifest_path.write_text(json.dumps(manifest, sort_keys=True, indent=2)+"\n", encoding="utf-8")
    return manifest


def verify_snapshot(root: Path, sql_path: Path, manifest_path: Path) -> dict:
    root=root.resolve(); manifest=json.loads(manifest_path.read_text(encoding="utf-8")); errors=[]
    if sha256_file(sql_path)!=manifest["sql_sha256"]: errors.append("SQL snapshot hash mismatch")
    with tempfile.TemporaryDirectory(prefix="ocsa-sql-restore-") as temporary:
        restored=Path(temporary)/"atlas.db"; connection=sqlite3.connect(restored)
        try:
            connection.executescript(sql_path.read_text(encoding="utf-8")); connection.commit(); quick=connection.execute("PRAGMA quick_check").fetchall(); foreign=connection.execute("PRAGMA foreign_key_check").fetchall()
        finally: connection.close()
        if quick != [("ok",)]: errors.append(f"restored SQLite quick_check failed: {quick!r}")
        if foreign: errors.append(f"restored SQLite foreign_key_check returned {len(foreign)} row(s)")
        inventory=logical_inventory(restored)
        if inventory["logical_sha256"]!=manifest["logical_sha256"]: errors.append("restored logical database digest mismatch")
        if inventory["table_counts"]!=manifest["table_counts"]: errors.append("restored table counts mismatch")
        if inventory["table_sha256"]!=manifest["table_sha256"]: errors.append("restored per-table digests mismatch")
        validation=subprocess.run([sys.executable,"src/ocsa_store.py","--db",str(restored),"--schema","schema.sql","--root",str(root),"validate"],cwd=root,text=True,capture_output=True)
        if validation.returncode: errors.append("restored SQL database failed OCSA validation: "+validation.stdout+validation.stderr)
    return {"passed":not errors,"errors":errors,"sql_sha256":sha256_file(sql_path),"logical_sha256":manifest["logical_sha256"],"validation_stdout":validation.stdout}


def main() -> int:
    parser=argparse.ArgumentParser(description="Export or verify the GitHub-friendly OCSA SQL recovery snapshot"); parser.add_argument("--root",type=Path,default=Path(__file__).resolve().parents[1]); sub=parser.add_subparsers(dest="command",required=True)
    export=sub.add_parser("export"); export.add_argument("--sql",type=Path); export.add_argument("--manifest",type=Path)
    verify=sub.add_parser("verify"); verify.add_argument("--sql",type=Path); verify.add_argument("--manifest",type=Path)
    args=parser.parse_args(); root=args.root.resolve(); sql_path=(args.sql or root/"recovery/atlas.sql").resolve(); manifest_path=(args.manifest or root/"recovery/atlas-sql-manifest.json").resolve()
    if args.command=="export": result={"passed":True,**export_snapshot(root,sql_path,manifest_path)}
    else: result=verify_snapshot(root,sql_path,manifest_path)
    print(json.dumps(result,sort_keys=True,indent=2)); return 0 if result.get("passed") else 1


if __name__ == "__main__":
    raise SystemExit(main())
