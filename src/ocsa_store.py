from __future__ import annotations

import argparse
import json
import sqlite3
from pathlib import Path
from typing import Any


class AtlasStore:
    """Small, dependency-light entry point for initializing and validating OCSA."""

    def __init__(self, db_path: Path, schema_path: Path):
        self.db_path = Path(db_path)
        self.schema_path = Path(schema_path)

    def connect(self) -> sqlite3.Connection:
        con = sqlite3.connect(self.db_path)
        con.row_factory = sqlite3.Row
        con.execute("PRAGMA foreign_keys = ON")
        return con

    def init(self) -> None:
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        with self.connect() as con:
            con.executescript(self.schema_path.read_text(encoding="utf-8"))
            defaults = {
                "project_name": "Opioid Causal Systems Atlas",
                "schema_version": "0.1.0",
                "dataset_revision": "0",
                "claim_default_state": "proposed",
            }
            for key, value in defaults.items():
                con.execute(
                    "INSERT OR IGNORE INTO metadata(key,value) VALUES(?,?)",
                    (key, value),
                )

    def stats(self) -> dict[str, Any]:
        tables = [
            "sources",
            "entities",
            "notes",
            "claims",
            "contradictions",
            "open_questions",
            "documents",
            "embedding_models",
            "embeddings",
            "embedding_queue",
        ]
        with self.connect() as con:
            return {
                "tables": {
                    table: con.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
                    for table in tables
                },
                "metadata": {
                    row["key"]: row["value"]
                    for row in con.execute("SELECT key,value FROM metadata")
                },
            }

    def validate(self) -> list[str]:
        errors: list[str] = []
        with self.connect() as con:
            integrity = con.execute("PRAGMA integrity_check").fetchone()[0]
            if integrity != "ok":
                errors.append(f"sqlite_integrity:{integrity}")

            for row in con.execute("PRAGMA foreign_key_check"):
                errors.append(f"foreign_key:{tuple(row)}")

            bad_claims = con.execute(
                """
                SELECT id FROM claims
                WHERE (object_entity_id IS NULL AND object_literal IS NULL)
                   OR (object_entity_id IS NOT NULL AND object_literal IS NOT NULL)
                """
            ).fetchall()
            errors.extend(f"claim_object:{row['id']}" for row in bad_claims)

            accepted_without_locator = con.execute(
                """
                SELECT id FROM claims
                WHERE status='accepted'
                  AND (source_locator IS NULL OR trim(source_locator)='')
                """
            ).fetchall()
            errors.extend(
                f"accepted_claim_missing_locator:{row['id']}"
                for row in accepted_without_locator
            )

            dangling_embeddings = con.execute(
                """
                SELECT e.document_id,e.model_id
                FROM embeddings e
                LEFT JOIN documents d ON d.id=e.document_id
                LEFT JOIN embedding_models m ON m.id=e.model_id
                WHERE d.id IS NULL OR m.id IS NULL
                """
            ).fetchall()
            errors.extend(
                f"dangling_embedding:{row['document_id']}:{row['model_id']}"
                for row in dangling_embeddings
            )
        return errors


def build_parser() -> argparse.ArgumentParser:
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description="OCSA database utility")
    parser.add_argument("--db", type=Path, default=root / "atlas.db")
    parser.add_argument("--schema", type=Path, default=root / "schema.sql")
    parser.add_argument("command", choices=["init", "validate", "stats"])
    return parser


def main() -> int:
    args = build_parser().parse_args()
    store = AtlasStore(args.db, args.schema)
    if args.command == "init":
        store.init()
        print(json.dumps(store.stats(), indent=2))
        return 0
    if not args.db.exists():
        store.init()
    if args.command == "stats":
        print(json.dumps(store.stats(), indent=2))
        return 0
    errors = store.validate()
    print(json.dumps({"valid": not errors, "errors": errors}, indent=2))
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
