from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import shutil
import sqlite3
import sys
import uuid
from contextlib import contextmanager
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable
from xml.sax.saxutils import escape

SCHEMA_VERSION = "0.2.3"
VALIDATOR_VERSION = "0.2.3"
CLAIM_STATES = {
    "proposed", "source_verified", "evidence_anchored", "extraction_verified",
    "reviewed", "accepted", "disputed", "rejected", "superseded",
    "retracted", "duplicate", "insufficient_evidence",
}
CAUSAL_PREDICATES = {"CAUSES", "REQUIRED_FOR", "SUFFICIENT_FOR"}
REQUIRED_TABLES = {
    "metadata", "research_runs", "run_events", "source_records", "source_files",
    "source_versions", "source_authenticity_checks", "paper_dossiers", "entities",
    "entity_versions", "evidence_spans", "claims", "claim_versions", "claim_evidence",
    "claim_reviews", "contradictions", "contradiction_versions", "open_questions",
    "question_versions", "allowed_semantic_patterns", "validation_runs",
    "validation_findings", "graph_diffs", "snapshots", "release_records", "release_files",
}
REQUIRED_VIEWS = {
    "current_source_versions", "current_entity_versions", "current_claim_versions",
    "current_evidence_spans", "current_claim_reviews",
    "full_research_graph", "provisional_graph", "canonical_graph", "contradiction_graph",
}
APPEND_ONLY_TABLES = {
    "source_versions", "source_files", "entity_versions", "evidence_spans",
    "claim_versions", "claim_evidence", "claim_reviews", "contradiction_versions",
    "question_versions", "run_events", "validation_runs", "validation_findings",
    "graph_diffs", "snapshots", "release_records", "release_files",
}


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def canonical_json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_text(text: str) -> str:
    return sha256_bytes(text.encode("utf-8"))


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def stable_id(prefix: str, *parts: Any) -> str:
    text = "\x1f".join(str(p) for p in parts)
    return f"{prefix}-{sha256_text(text)[:24]}"


def is_hex64(value: str | None) -> bool:
    return bool(value and len(value) == 64 and all(c in "0123456789abcdef" for c in value))


def read_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, sort_keys=True, indent=2) + "\n", encoding="utf-8")


@dataclass
class Finding:
    validator: str
    severity: str
    code: str
    message: str
    object_type: str | None = None
    object_id: str | None = None
    details: dict[str, Any] | None = None

    def as_dict(self) -> dict[str, Any]:
        return {
            "validator": self.validator,
            "severity": self.severity,
            "code": self.code,
            "message": self.message,
            "object_type": self.object_type,
            "object_id": self.object_id,
            "details": self.details or {},
        }


@dataclass
class AtlasStore:
    db_path: Path
    schema_path: Path
    root: Path

    @contextmanager
    def connection(self, *, write: bool = False):
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        con = sqlite3.connect(self.db_path)
        con.row_factory = sqlite3.Row
        con.execute("PRAGMA foreign_keys=ON")
        con.execute("PRAGMA busy_timeout=5000")
        try:
            if write:
                con.execute("BEGIN IMMEDIATE")
            yield con
            if write:
                con.commit()
        except Exception:
            if write:
                con.rollback()
            raise
        finally:
            con.close()

    def init(self) -> None:
        if not self.schema_path.is_file():
            raise FileNotFoundError(self.schema_path)
        with self.connection(write=True) as con:
            con.executescript(self.schema_path.read_text(encoding="utf-8"))
            defaults = {
                "project_name": "Opioid Causal Systems Atlas",
                "schema_version": SCHEMA_VERSION,
                "validator_version": VALIDATOR_VERSION,
                "dataset_revision": "0",
                "claim_default_state": "proposed",
                "canonical_graph_state": "accepted",
                "created_at": utc_now(),
                "last_updated_at": utc_now(),
            }
            for key, value in defaults.items():
                con.execute("INSERT OR IGNORE INTO metadata(key,value) VALUES(?,?)", (key, value))
            patterns = [
                ("gene", "HAS_APPROVED_GENE_IDENTITY", "literal"),
                ("gene", "HAS_REVIEWED_UNIPROT_ENTRY", "protein"),
                ("gene", "MAPS_TO_IUPHAR_RECEPTOR_TARGET", "receptor_target"),
                ("ligand", "AGONIZES", "receptor_target"),
                ("receptor_target", "COUPLES_TO", "g_protein"),
                ("neuron", "PROJECTS_TO", "brain_region"),
                ("brain_region", "CONTAINS", "cell_population"),
            ]
            con.executemany(
                "INSERT OR IGNORE INTO allowed_semantic_patterns(subject_type,predicate,object_type) VALUES(?,?,?)",
                patterns,
            )

    def migrate_reconciliation_schema(self) -> None:
        """Atomically extend a 0.2.2 database; never rewrite scientific rows."""
        additions = {
            "entity_versions": ["chromosomal_location TEXT", "metadata_json TEXT NOT NULL DEFAULT '{}'"],
            "evidence_spans": ["version_no INTEGER NOT NULL DEFAULT 1 CHECK(version_no > 0)",
                               "supersedes_evidence_span_id TEXT REFERENCES evidence_spans(evidence_span_id)",
                               "change_reason TEXT"],
            "claim_reviews": ["version_no INTEGER NOT NULL DEFAULT 1 CHECK(version_no > 0)",
                              "supersedes_review_id TEXT REFERENCES claim_reviews(review_id)",
                              "recorded_in_run TEXT REFERENCES research_runs(run_id)",
                              "change_reason TEXT"],
        }
        with self.connection(write=True) as con:
            version = con.execute("SELECT value FROM metadata WHERE key='schema_version'").fetchone()
            if not version or version[0] not in ("0.2.2", SCHEMA_VERSION):
                raise ValueError("Unsupported schema version for reconciliation migration")
            for table, columns in additions.items():
                present = {r[1] for r in con.execute(f"PRAGMA table_info({table})")}
                for definition in columns:
                    if definition.split()[0] not in present:
                        con.execute(f"ALTER TABLE {table} ADD COLUMN {definition}")
            con.execute("CREATE UNIQUE INDEX IF NOT EXISTS one_successor_per_evidence_span "
                        "ON evidence_spans(supersedes_evidence_span_id) WHERE supersedes_evidence_span_id IS NOT NULL")
            con.execute("CREATE UNIQUE INDEX IF NOT EXISTS one_successor_per_review "
                        "ON claim_reviews(supersedes_review_id) WHERE supersedes_review_id IS NOT NULL")
            con.execute("CREATE VIEW IF NOT EXISTS current_evidence_spans AS SELECT ev.* FROM evidence_spans ev "
                        "WHERE NOT EXISTS (SELECT 1 FROM evidence_spans newer "
                        "WHERE newer.supersedes_evidence_span_id=ev.evidence_span_id)")
            con.execute("CREATE VIEW IF NOT EXISTS current_claim_reviews AS SELECT cr.* FROM claim_reviews cr "
                        "WHERE NOT EXISTS (SELECT 1 FROM claim_reviews newer "
                        "WHERE newer.supersedes_review_id=cr.review_id)")
            canonical_view = con.execute("SELECT sql FROM sqlite_master WHERE name='canonical_graph'").fetchone()
            if canonical_view is None or "current_claim_reviews" not in canonical_view[0]:
                con.execute("DROP VIEW IF EXISTS canonical_graph")
                con.execute("""CREATE VIEW canonical_graph AS SELECT cv.* FROM current_claim_versions cv
                WHERE cv.state='accepted' AND cv.review_tier>=2 AND cv.context_json<>'{}'
                AND EXISTS (SELECT 1 FROM claim_evidence ce JOIN evidence_spans es
                    ON es.evidence_span_id=ce.evidence_span_id JOIN source_files sf
                    ON sf.sha256=es.source_file_sha256 WHERE ce.claim_version_id=cv.claim_version_id)
                AND EXISTS (SELECT 1 FROM current_claim_reviews cr WHERE cr.claim_version_id=cv.claim_version_id
                    AND cr.review_pass=2 AND cr.independent=1 AND cr.result='agree')
                AND NOT EXISTS (SELECT 1 FROM claim_evidence ce JOIN evidence_spans es
                    ON es.evidence_span_id=ce.evidence_span_id LEFT JOIN source_authenticity_checks sac
                    ON sac.source_version_id=es.source_version_id AND sac.resolution_status='pass'
                    WHERE ce.claim_version_id=cv.claim_version_id AND sac.check_id IS NULL)""")
            if version[0] != SCHEMA_VERSION:
                con.execute("UPDATE metadata SET value=? WHERE key='schema_version'", (SCHEMA_VERSION,))
            if con.execute("SELECT value FROM metadata WHERE key='validator_version'").fetchone()[0] != VALIDATOR_VERSION:
                con.execute("UPDATE metadata SET value=? WHERE key='validator_version'", (VALIDATOR_VERSION,))

    def stats(self) -> dict[str, Any]:
        with self.connection() as con:
            counts = {}
            for table in sorted(REQUIRED_TABLES):
                counts[table] = con.execute(f"SELECT count(*) FROM {table}").fetchone()[0]
            counts["canonical_graph"] = con.execute("SELECT count(*) FROM canonical_graph").fetchone()[0]
            counts["provisional_graph"] = con.execute("SELECT count(*) FROM provisional_graph").fetchone()[0]
            counts["metadata"] = {r["key"]: r["value"] for r in con.execute("SELECT key,value FROM metadata ORDER BY key")}
            return counts

    def create_run(self, *, run_id: str, module: str, scope: str, status: str = "staging",
                   parent_release: str | None = None, parent_database_sha256: str | None = None,
                   prompt_sha256: str | None = None, search_protocol_version: str = "0.2.2") -> None:
        now = utc_now()
        with self.connection(write=True) as con:
            con.execute(
                """INSERT INTO research_runs(run_id,module,scope,status,parent_release,parent_database_sha256,
                prompt_sha256,search_protocol_version,started_at,created_at) VALUES(?,?,?,?,?,?,?,?,?,?)""",
                (run_id, module, scope, status, parent_release, parent_database_sha256,
                 prompt_sha256, search_protocol_version, now, now),
            )
            self._append_event(con, run_id, "run_started", {"module": module, "scope": scope})

    def _append_event(self, con: sqlite3.Connection, run_id: str, event_type: str, payload: dict[str, Any]) -> str:
        prior = con.execute(
            "SELECT sequence_no,event_hash FROM run_events WHERE run_id=? ORDER BY sequence_no DESC LIMIT 1",
            (run_id,),
        ).fetchone()
        seq = (prior["sequence_no"] + 1) if prior else 1
        previous = prior["event_hash"] if prior else None
        created = utc_now()
        payload_text = canonical_json(payload)
        material = canonical_json({"run_id": run_id, "sequence_no": seq, "event_type": event_type,
                                   "payload_json": payload_text, "previous_event_hash": previous,
                                   "created_at": created})
        event_hash = sha256_text(material)
        event_id = stable_id("evt", run_id, seq, event_hash)
        con.execute(
            "INSERT INTO run_events(event_id,run_id,sequence_no,event_type,payload_json,previous_event_hash,event_hash,created_at) VALUES(?,?,?,?,?,?,?,?)",
            (event_id, run_id, seq, event_type, payload_text, previous, event_hash, created),
        )
        return event_id

    def append_event(self, run_id: str, event_type: str, payload: dict[str, Any]) -> str:
        with self.connection(write=True) as con:
            return self._append_event(con, run_id, event_type, payload)

    def snapshot(self, run_id: str, phase: str, output: Path) -> dict[str, Any]:
        output.parent.mkdir(parents=True, exist_ok=True)
        with self.connection() as src:
            dst = sqlite3.connect(output)
            try:
                src.backup(dst)
            finally:
                dst.close()
        record = {"path": output.relative_to(self.root).as_posix() if output.is_relative_to(self.root) else str(output),
                  "sha256": sha256_file(output), "size_bytes": output.stat().st_size}
        with self.connection(write=True) as con:
            con.execute(
                "INSERT INTO snapshots(snapshot_id,run_id,phase,path,sha256,size_bytes,created_at) VALUES(?,?,?,?,?,?,?)",
                (stable_id("snap", run_id, phase, record["sha256"]), run_id, phase, record["path"],
                 record["sha256"], record["size_bytes"], utc_now()),
            )
            self._append_event(con, run_id, "snapshot_created", {"phase": phase, **record})
        return record

    def ingest_module1_staging(self, run_dir: Path, *, run_id: str) -> dict[str, int]:
        entities = [json.loads(x) for x in (run_dir / "entities.jsonl").read_text(encoding="utf-8").splitlines() if x.strip()]
        sources_doc = read_json(run_dir / "source_manifest.json")
        sources = sources_doc["database_record_sources"]
        evidence = [json.loads(x) for x in (run_dir / "evidence_spans.jsonl").read_text(encoding="utf-8").splitlines() if x.strip()]
        claims = [json.loads(x) for x in (run_dir / "proposed_assertions.jsonl").read_text(encoding="utf-8").splitlines() if x.strip()]
        reviews = [json.loads(x) for x in (run_dir / "verification.jsonl").read_text(encoding="utf-8").splitlines() if x.strip()]
        questions = read_json(run_dir / "open_questions.json")["questions"]
        now = utc_now()
        with self.connection(write=True) as con:
            for src in sources:
                sid = src["source_id"]
                con.execute("INSERT OR IGNORE INTO source_records(source_id,created_in_run,created_at) VALUES(?,?,?)", (sid,run_id,now))
                svid = f"{sid}-v1"
                con.execute(
                    """INSERT INTO source_versions(source_version_id,source_id,version_no,title,journal_or_repository,
                    original_url,resolved_url,source_type,species,access_status,extraction_status,metadata_json,
                    change_reason,created_in_run,created_at) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
                    (svid,sid,1,src["title"],src["database"],src["url"],src["url"],src["source_type"],
                     src.get("species"),"public_web_access","structured_fields_extracted",canonical_json(src),
                     "Module 1A identifier seed",run_id,now),
                )
                con.execute(
                    "INSERT INTO source_authenticity_checks(check_id,source_version_id,resolution_status,details_json,checked_in_run,checked_at) VALUES(?,?,?,?,?,?)",
                    (stable_id("sac",svid),svid,"partial",canonical_json({"reason":"metadata cross-check only; immutable file absent"}),run_id,now),
                )
            for ent in entities:
                eid = ent["entity_id"]
                evid = f"{eid}-v1"
                con.execute("INSERT OR IGNORE INTO entities(entity_id,created_in_run,created_at) VALUES(?,?,?)",(eid,run_id,now))
                con.execute(
                    """INSERT INTO entity_versions(entity_version_id,entity_id,version_no,entity_type,canonical_label,species,
                    identifiers_json,aliases_json,definition,status,change_reason,created_in_run,created_at)
                    VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?)""",
                    (evid,eid,1,ent["entity_type"],ent["canonical_label"],ent.get("species"),
                     canonical_json(ent.get("identifiers",{})),canonical_json(ent.get("aliases",[])),ent.get("name"),
                     "proposed","Module 1A identifier seed",run_id,now),
                )
            for ev in evidence:
                sid = ev["source_id"]
                con.execute(
                    """INSERT INTO evidence_spans(evidence_span_id,source_version_id,source_file_sha256,section_locator,
                    excerpt,excerpt_sha256,evidence_role,extraction_method,context_json,created_in_run,created_at)
                    VALUES(?,?,?,?,?,?,?,?,?,?,?)""",
                    (ev["evidence_id"],f"{sid}-v1",None,ev.get("section"),ev["excerpt"],ev["excerpt_sha256"],
                     ev["evidence_role"],ev["extraction_method"],canonical_json({"species":"Homo sapiens"}),run_id,now),
                )
            review_by_claim = {r["assertion_id"]: r for r in reviews}
            for claim in claims:
                cid = claim["assertion_id"]
                cvid = f"{cid}-v1"
                con.execute("INSERT OR IGNORE INTO claims(claim_id,created_in_run,created_at) VALUES(?,?,?)",(cid,run_id,now))
                obj = claim["object"]
                linked = obj.get("protein_entity_id") or obj.get("target_entity_id")
                object_entity_version_id = f"{linked}-v1" if linked else None
                object_literal = None if linked else canonical_json(obj)
                con.execute(
                    """INSERT INTO claim_versions(claim_version_id,claim_id,version_no,subject_entity_version_id,predicate,
                    object_entity_version_id,object_literal,polarity,causal_strength,context_json,numerical_result_json,state,review_tier,change_reason,
                    created_in_run,created_at) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
                    (cvid,cid,1,f"{claim['subject_entity_id']}-v1",claim["predicate"],object_entity_version_id,object_literal,
                     "positive","descriptive",canonical_json({"species":"Homo sapiens"}),"{}","proposed",1,
                     "Module 1A proposed identity assertion",run_id,now),
                )
                for evidence_id in claim["evidence_ids"]:
                    con.execute("INSERT INTO claim_evidence(claim_version_id,evidence_span_id,evidence_weight) VALUES(?,?,?)",(cvid,evidence_id,"supporting"))
                rv = review_by_claim[cid]
                con.execute(
                    """INSERT INTO claim_reviews(review_id,claim_version_id,review_pass,reviewer_class,independent,result,
                    checks_json,notes,reviewed_in_run,reviewed_at) VALUES(?,?,?,?,?,?,?,?,?,?)""",
                    (rv["verification_id"],cvid,2,rv["reviewer_class"],0,rv["result"],
                     canonical_json({"scope":"identity fields"}),rv["independence_limit"],run_id,rv["verified_at"]),
                )
            for q in questions:
                qid=q["id"]
                con.execute("INSERT OR IGNORE INTO open_questions(question_id,created_in_run,created_at) VALUES(?,?,?)",(qid,run_id,now))
                con.execute(
                    """INSERT INTO question_versions(question_version_id,question_id,version_no,question,priority,status,
                    change_reason,created_in_run,created_at) VALUES(?,?,?,?,?,?,?,?,?)""",
                    (f"{qid}-v1",qid,1,q["question"],q["priority"],q["status"],"Module 1A open question",run_id,now),
                )
            self._append_event(con,run_id,"staging_ingested",{"sources":len(sources),"entities":len(entities),"evidence":len(evidence),"claims":len(claims),"questions":len(questions)})
        return {"sources":len(sources),"entities":len(entities),"evidence_spans":len(evidence),"claims":len(claims),"reviews":len(reviews),"questions":len(questions)}

    def reconcile_module1_metadata(self, run_dir: Path, *, run_id: str, verified_manifest: Path) -> dict[str, int]:
        """Append historical staging corrections, without re-authenticating sources or promoting claims."""
        manifest = read_json(verified_manifest)
        run_dir = run_dir.resolve()
        if not run_dir.is_relative_to(self.root.resolve()):
            raise ValueError("Staging directory must be within the atlas root")
        old_manifest = run_dir / "FILE_MANIFEST.json"
        historical_outer = self.root / "manifests/RELEASE_MANIFEST_PRE_RECONCILIATION.json"
        outer_files = {item["path"]: item for item in read_json(historical_outer)["files"]}
        old_relative = old_manifest.relative_to(self.root).as_posix()
        old_entry = {"path": old_relative, "sha256": sha256_file(old_manifest),
                     "size_bytes": old_manifest.stat().st_size}
        if old_entry != outer_files.get(old_relative):
            raise ValueError("Historical inner manifest does not match outer release manifest")
        if (manifest.get("supersedes_manifest_sha256") != sha256_file(old_manifest)
                or manifest.get("supersedes_manifest") != old_manifest.relative_to(self.root).as_posix()
                or manifest.get("outer_release_manifest_sha256") != sha256_file(historical_outer)
                or manifest.get("authenticates_historical_metadata") is not False
                or manifest.get("status") != "current_bytes_verified_historical_mismatch"):
            raise ValueError("Reconciled staging manifest lacks required historical provenance")
        historical_paths = {item["path"] for item in read_json(old_manifest)["files"]}
        if {item["path"] for item in manifest["files"]} != historical_paths:
            raise ValueError("Reconciled manifest path set differs from historical staging manifest")
        historical_records = {item["path"]: item for item in read_json(old_manifest)["files"]}
        actual_mismatches = [{"path": item["path"], "historical_record": historical_records[item["path"]],
                              "current_bytes": item} for item in manifest["files"]
                             if item != historical_records[item["path"]]]
        if sorted(actual_mismatches, key=lambda x:x["path"]) != sorted(
                manifest.get("historical_mismatches", []), key=lambda x:x["path"]):
            raise ValueError("Historical mismatch accounting is inconsistent")
        verified_bytes = {}
        for item in manifest["files"]:
            rel = Path(item["path"])
            if rel.is_absolute() or ".." in rel.parts or rel.as_posix() in verified_bytes:
                raise ValueError(f"Unsafe or duplicate staging path: {rel}")
            if item != outer_files.get(rel.as_posix()):
                raise ValueError(f"Staging entry does not match outer release manifest: {rel}")
            path = (self.root / rel).resolve()
            if not path.is_relative_to(self.root.resolve()) or not path.is_file():
                raise ValueError(f"Staging path is missing or escapes root: {rel}")
            data = path.read_bytes()
            if len(data) != item["size_bytes"] or sha256_bytes(data) != item["sha256"]:
                raise ValueError(f"Staging file failed current-byte verification: {rel}")
            verified_bytes[rel.as_posix()] = data
        required = {run_dir.relative_to(self.root).joinpath(name).as_posix() for name in
                    ("entities.jsonl", "source_manifest.json", "evidence_spans.jsonl", "verification.jsonl")}
        if not required <= verified_bytes.keys():
            raise ValueError("Reconciled manifest omits required staging inputs")
        def verified_input(name: str) -> str:
            return verified_bytes[(run_dir / name).relative_to(self.root).as_posix()].decode("utf-8")
        entities = [json.loads(x) for x in verified_input("entities.jsonl").splitlines() if x.strip()]
        sources = json.loads(verified_input("source_manifest.json"))["database_record_sources"]
        evidence = [json.loads(x) for x in verified_input("evidence_spans.jsonl").splitlines() if x.strip()]
        reviews = [json.loads(x) for x in verified_input("verification.jsonl").splitlines() if x.strip()]
        changes = {"source_versions": 0, "entity_versions": 0, "evidence_spans": 0, "claim_reviews": 0}
        now = utc_now()
        with self.connection(write=True) as con:
            if con.execute("SELECT 1 FROM research_runs WHERE run_id=?", (run_id,)).fetchone() is None:
                raise ValueError("Reconciliation run must already exist")
            if con.execute("SELECT count(*) FROM canonical_graph").fetchone()[0]:
                raise ValueError("Metadata-only reconciliation requires zero canonical claims")
            for src in sources:
                old = con.execute("SELECT * FROM current_source_versions WHERE source_id=?", (src["source_id"],)).fetchone()
                if old is None: raise ValueError(f"Unknown source {src['source_id']}")
                merged = {**json.loads(old["metadata_json"]), **src}
                values = {"original_url": src["url"], "resolved_url": src["url"],
                          "correction_retraction_status": src["correction_retraction_status"],
                          "access_status": src["license_or_access_status"],
                          "extraction_status": src["extraction_status"],
                          "metadata_json": canonical_json(merged)}
                if all(old[k] == v for k, v in values.items()): continue
                row = dict(old); row.update(values)
                row.update(source_version_id=f"{src['source_id']}-v{old['version_no']+1}",
                           version_no=old["version_no"]+1,
                           supersedes_source_version_id=old["source_version_id"],
                           change_reason="Archived staging metadata reconciliation; source not re-authenticated",
                           created_in_run=run_id, created_at=now)
                cols = list(row)
                con.execute(f"INSERT INTO source_versions({','.join(cols)}) VALUES({','.join('?' for _ in cols)})",
                            tuple(row[c] for c in cols))
                changes["source_versions"] += 1
            for ent in entities:
                if not ent.get("chromosomal_location"): continue
                old = con.execute("SELECT * FROM current_entity_versions WHERE entity_id=?", (ent["entity_id"],)).fetchone()
                if old is None: raise ValueError(f"Unknown entity {ent['entity_id']}")
                extra = {k: ent[k] for k in ("family", "transmembrane_helices") if k in ent}
                values = {"aliases_json": canonical_json(ent.get("aliases", [])),
                          "chromosomal_location": ent["chromosomal_location"],
                          "metadata_json": canonical_json(extra)}
                if all(old[k] == v for k, v in values.items()): continue
                row = dict(old); row.update(values)
                row.update(entity_version_id=f"{ent['entity_id']}-v{old['version_no']+1}",
                           version_no=old["version_no"]+1,
                           supersedes_entity_version_id=old["entity_version_id"],
                           change_reason="Archived staging fields; biological identity not independently rechecked",
                           created_in_run=run_id, created_at=now)
                cols = list(row)
                con.execute(f"INSERT INTO entity_versions({','.join(cols)}) VALUES({','.join('?' for _ in cols)})",
                            tuple(row[c] for c in cols))
                changes["entity_versions"] += 1
            for ev in evidence:
                original_id = ev["evidence_id"]
                old = con.execute("""WITH RECURSIVE lineage(evidence_span_id) AS (
                    SELECT ? UNION ALL SELECT e.evidence_span_id FROM evidence_spans e
                    JOIN lineage l ON e.supersedes_evidence_span_id=l.evidence_span_id)
                    SELECT e.* FROM evidence_spans e JOIN lineage l USING(evidence_span_id)
                    ORDER BY e.version_no DESC LIMIT 1""", (original_id,)).fetchone()
                if old is None: raise ValueError(f"Unknown evidence {original_id}")
                if old["excerpt"] != ev["excerpt"] or old["excerpt_sha256"] != ev["excerpt_sha256"]:
                    raise ValueError(f"Evidence excerpt changed unexpectedly: {original_id}")
                if old["section_locator"] == ev.get("section"): continue
                row = dict(old)
                row.update(evidence_span_id=f"{original_id}-v{old['version_no']+1}",
                           version_no=old["version_no"]+1,
                           supersedes_evidence_span_id=old["evidence_span_id"],
                           section_locator=ev.get("section"),
                           change_reason="More precise locator from archived staging; excerpt unchanged",
                           created_in_run=run_id, created_at=now)
                cols = list(row)
                con.execute(f"INSERT INTO evidence_spans({','.join(cols)}) VALUES({','.join('?' for _ in cols)})",
                            tuple(row[c] for c in cols))
                changes["evidence_spans"] += 1
            for rv in reviews:
                original_id = rv["verification_id"]
                old = con.execute("""WITH RECURSIVE lineage(review_id) AS (
                    SELECT ? UNION ALL SELECT r.review_id FROM claim_reviews r
                    JOIN lineage l ON r.supersedes_review_id=l.review_id)
                    SELECT r.* FROM claim_reviews r JOIN lineage l USING(review_id)
                    ORDER BY r.version_no DESC LIMIT 1""", (original_id,)).fetchone()
                if old is None: raise ValueError(f"Unknown review {original_id}")
                if (old["independent"] != 0 or old["reviewer_class"] != rv["reviewer_class"]
                        or old["reviewed_at"] != rv["verified_at"]):
                    raise ValueError(f"Unexpected review provenance: {original_id}")
                checks = {**json.loads(old["checks_json"]), "scope_checked": rv["scope_checked"]}
                if old["checks_json"] == canonical_json(checks): continue
                row = dict(old)
                row.update(review_id=f"{original_id}-v{old['version_no']+1}",
                           version_no=old["version_no"]+1,
                           supersedes_review_id=old["review_id"],
                           checks_json=canonical_json(checks), recorded_in_run=run_id,
                           change_reason="Historical review scope transcribed from archived staging")
                cols = list(row)
                con.execute(f"INSERT INTO claim_reviews({','.join(cols)}) VALUES({','.join('?' for _ in cols)})",
                            tuple(row[c] for c in cols))
                changes["claim_reviews"] += 1
            if any(changes.values()):
                self._append_event(con, run_id, "metadata_reconciled", {**changes,
                    "manifest_sha256": sha256_file(verified_manifest), "source_authentication": "not_rechecked"})
        return changes

    def _json_findings(self, con: sqlite3.Connection) -> list[Finding]:
        findings=[]
        specs={
            "source_versions":["authors_json","metadata_json"],
            "paper_dossiers":["dossier_json"],
            "entity_versions":["identifiers_json","aliases_json","metadata_json"],
            "evidence_spans":["context_json"],
            "claim_versions":["context_json","numerical_result_json"],
            "claim_reviews":["checks_json"],
            "contradiction_versions":["evidence_context_json","possible_explanations_json"],
            "question_versions":["linked_entity_ids_json"],
            "validation_findings":["details_json"],
            "graph_diffs":["details_json"],
            "research_runs":["model_json","tool_versions_json"],
            "run_events":["payload_json"],
        }
        for table,cols in specs.items():
            for col in cols:
                rows=con.execute(f"SELECT rowid,{col} value FROM {table} WHERE json_valid({col})=0").fetchall()
                for r in rows: findings.append(Finding("structural","blocking","INVALID_JSON",f"Invalid JSON in {table}.{col}",table,str(r['rowid'])))
        return findings

    def validate(self, *, store_result_for_run: str | None = None) -> dict[str, Any]:
        started=utc_now(); findings: list[Finding]=[]
        try:
            with self.connection() as con:
                integrity=con.execute("PRAGMA integrity_check").fetchone()[0]
                if integrity!="ok": findings.append(Finding("structural","blocking","SQLITE_INTEGRITY",integrity))
                for row in con.execute("PRAGMA foreign_key_check"):
                    findings.append(Finding("structural","blocking","FOREIGN_KEY",f"Foreign key failure: {tuple(row)}"))
                objects={r["name"]:r["type"] for r in con.execute("SELECT name,type FROM sqlite_master WHERE name NOT LIKE 'sqlite_%'")}
                for table in REQUIRED_TABLES-objects.keys(): findings.append(Finding("structural","blocking","MISSING_TABLE",f"Missing table {table}","table",table))
                for view in REQUIRED_VIEWS-objects.keys(): findings.append(Finding("structural","blocking","MISSING_VIEW",f"Missing view {view}","view",view))
                canonical_sql = con.execute("SELECT sql FROM sqlite_master WHERE name='canonical_graph'").fetchone()
                if canonical_sql and "current_claim_reviews" not in canonical_sql[0]:
                    findings.append(Finding("release","blocking","STALE_CANONICAL_VIEW",
                        "Canonical eligibility must use current review revisions", "view", "canonical_graph"))
                for table, columns in {
                    "entity_versions": ("chromosomal_location", "metadata_json"),
                    "evidence_spans": ("version_no", "supersedes_evidence_span_id", "change_reason"),
                    "claim_reviews": ("version_no", "supersedes_review_id", "recorded_in_run", "change_reason"),
                }.items():
                    present = {r[1] for r in con.execute(f"PRAGMA table_info({table})")}
                    for column in set(columns)-present:
                        findings.append(Finding("structural","blocking","MISSING_COLUMN",f"Missing {table}.{column}",table,column))
                for table in APPEND_ONLY_TABLES:
                    for op in ("update","delete"):
                        name=f"no_{op}_{table}"
                        if name not in objects: findings.append(Finding("structural","blocking","MISSING_APPEND_TRIGGER",f"Missing {name}","trigger",name))
                findings.extend(self._json_findings(con))
                for r in con.execute("SELECT claim_version_id,state FROM claim_versions WHERE version_no=1 AND state<>'proposed'"):
                    findings.append(Finding("logical","blocking","FIRST_CLAIM_NOT_PROPOSED","First claim version must be proposed","claim_version",r["claim_version_id"]))
                # Version chains.
                for table,prefix,idcol,supcol in [
                    ("source_versions","source","source_version_id","supersedes_source_version_id"),
                    ("entity_versions","entity","entity_version_id","supersedes_entity_version_id"),
                    ("claim_versions","claim","claim_version_id","supersedes_claim_version_id"),
                    ("contradiction_versions","contradiction","contradiction_version_id","supersedes_contradiction_version_id"),
                    ("question_versions","question","question_version_id","supersedes_question_version_id")]:
                    rows=con.execute(f"SELECT * FROM {table} ORDER BY {prefix}_id,version_no").fetchall()
                    groups={}
                    for r in rows: groups.setdefault(r[f"{prefix}_id"],[]).append(r)
                    for gid,items in groups.items():
                        for i,r in enumerate(items,1):
                            if r["version_no"]!=i: findings.append(Finding("structural","blocking","VERSION_GAP",f"{table} version gap",table,r[idcol]))
                            if i>1 and r[supcol]!=items[i-2][idcol]: findings.append(Finding("structural","blocking","BAD_SUPERSEDES",f"{table} supersedes chain invalid",table,r[idcol]))
                for table,idcol,supcol in (("evidence_spans","evidence_span_id","supersedes_evidence_span_id"),
                                           ("claim_reviews","review_id","supersedes_review_id")):
                    rows = {r[idcol]: r for r in con.execute(f"SELECT * FROM {table}")}
                    for ident, row in rows.items():
                        parent = rows.get(row[supcol]) if row[supcol] else None
                        if (row["version_no"] == 1) != (parent is None):
                            findings.append(Finding("structural","blocking","BAD_SUPERSEDES",f"{table} has invalid root/version",table,ident))
                        elif parent is not None and row["version_no"] != parent["version_no"] + 1:
                            findings.append(Finding("structural","blocking","VERSION_GAP",f"{table} version gap",table,ident))
                        elif parent is not None and table == "claim_reviews" and row["claim_version_id"] != parent["claim_version_id"]:
                            findings.append(Finding("structural","blocking","REVIEW_RETARGET",f"{table} retargeted a claim",table,ident))
                        elif parent is not None and table == "evidence_spans" and (row["source_version_id"] != parent["source_version_id"] or row["excerpt_sha256"] != parent["excerpt_sha256"]):
                            findings.append(Finding("structural","blocking","EVIDENCE_RETARGET",f"{table} changed source or excerpt",table,ident))
                # Evidence hashes and source files.
                for r in con.execute("SELECT evidence_span_id,excerpt,excerpt_sha256,source_file_sha256 FROM evidence_spans"):
                    if sha256_text(r["excerpt"])!=r["excerpt_sha256"]: findings.append(Finding("evidence","blocking","EXCERPT_HASH_MISMATCH","Evidence excerpt hash mismatch","evidence_span",r["evidence_span_id"]))
                for r in con.execute("SELECT sha256,immutable_path,size_bytes FROM source_files"):
                    path=self.root/r["immutable_path"]
                    if not path.is_file(): findings.append(Finding("source","blocking","SOURCE_FILE_MISSING",f"Missing {path}","source_file",r["sha256"]))
                    elif path.stat().st_size!=r["size_bytes"] or sha256_file(path)!=r["sha256"]: findings.append(Finding("source","blocking","SOURCE_FILE_HASH_MISMATCH",f"Source file mismatch {path}","source_file",r["sha256"]))
                # Semantic patterns.
                query="""SELECT cv.claim_version_id,sv.entity_type subject_type,cv.predicate,
                  CASE WHEN cv.object_entity_version_id IS NULL THEN 'literal' ELSE ov.entity_type END object_type
                  FROM current_claim_versions cv JOIN entity_versions sv ON sv.entity_version_id=cv.subject_entity_version_id
                  LEFT JOIN entity_versions ov ON ov.entity_version_id=cv.object_entity_version_id"""
                allowed={(r[0],r[1],r[2]) for r in con.execute("SELECT subject_type,predicate,object_type FROM allowed_semantic_patterns")}
                for r in con.execute(query):
                    if (r["subject_type"],r["predicate"],r["object_type"]) not in allowed:
                        findings.append(Finding("semantic","blocking","INVALID_SEMANTIC_PATTERN",f"{r['subject_type']} {r['predicate']} {r['object_type']} not allowed","claim_version",r["claim_version_id"]))
                for r in con.execute("SELECT claim_version_id,predicate,causal_strength,context_json FROM current_claim_versions"):
                    ctx=json.loads(r["context_json"])
                    if r["predicate"] in CAUSAL_PREDICATES and not ctx.get("causal_design"):
                        findings.append(Finding("logical","blocking","CAUSAL_OVERSTATEMENT",f"{r['predicate']} lacks causal_design","claim_version",r["claim_version_id"]))
                # Accepted gates.
                accepted=con.execute("SELECT * FROM current_claim_versions WHERE state='accepted'").fetchall()
                canonical_ids={r["claim_version_id"] for r in con.execute("SELECT claim_version_id FROM canonical_graph")}
                for r in accepted:
                    if r["claim_version_id"] not in canonical_ids:
                        findings.append(Finding("release","blocking","ACCEPTED_NOT_CANONICAL_ELIGIBLE","Accepted claim fails canonical gates","claim_version",r["claim_version_id"]))
                for r in con.execute("SELECT claim_version_id FROM canonical_graph WHERE state<>'accepted'"):
                    findings.append(Finding("release","blocking","NON_ACCEPTED_CANONICAL","Non-accepted claim in canonical graph","claim_version",r["claim_version_id"]))
                # Event chains.
                for run in con.execute("SELECT run_id FROM research_runs"):
                    prev=None
                    for r in con.execute("SELECT * FROM run_events WHERE run_id=? ORDER BY sequence_no",(run["run_id"],)):
                        material=canonical_json({"run_id":r["run_id"],"sequence_no":r["sequence_no"],"event_type":r["event_type"],"payload_json":r["payload_json"],"previous_event_hash":r["previous_event_hash"],"created_at":r["created_at"]})
                        if r["previous_event_hash"]!=prev or sha256_text(material)!=r["event_hash"]:
                            findings.append(Finding("logical","blocking","EVENT_HASH_CHAIN","Run event hash chain invalid","run_event",r["event_id"]))
                        prev=r["event_hash"]
                # Snapshot integrity.
                for r in con.execute("SELECT snapshot_id,path,sha256,size_bytes FROM snapshots"):
                    path=self.root/r["path"]
                    if not path.is_file(): findings.append(Finding("snapshot","blocking","SNAPSHOT_MISSING",f"Missing {path}","snapshot",r["snapshot_id"]))
                    elif path.stat().st_size!=r["size_bytes"] or sha256_file(path)!=r["sha256"]: findings.append(Finding("snapshot","blocking","SNAPSHOT_HASH_MISMATCH",f"Snapshot mismatch {path}","snapshot",r["snapshot_id"]))
        except sqlite3.DatabaseError as exc:
            findings.append(Finding("structural","blocking","DATABASE_ERROR",str(exc)))
        blocking=sum(f.severity=="blocking" for f in findings); warnings=sum(f.severity=="warning" for f in findings)
        report={"validator_version":VALIDATOR_VERSION,"database_sha256":sha256_file(self.db_path) if self.db_path.is_file() else None,"passed":blocking==0,"blocking_count":blocking,"warning_count":warnings,"finding_count":len(findings),"findings":[f.as_dict() for f in findings]}
        if store_result_for_run and self.db_path.is_file():
            completed=utc_now(); vid=stable_id("val",store_result_for_run,completed,report["database_sha256"])
            with self.connection(write=True) as con:
                con.execute("INSERT INTO validation_runs(validation_run_id,run_id,validator_version,database_sha256,passed,blocking_count,warning_count,started_at,completed_at) VALUES(?,?,?,?,?,?,?,?,?)",(vid,store_result_for_run,VALIDATOR_VERSION,report["database_sha256"],int(report["passed"]),blocking,warnings,started,completed))
                for idx,f in enumerate(findings,1):
                    con.execute("INSERT INTO validation_findings(finding_id,validation_run_id,validator_name,severity,code,object_type,object_id,message,details_json,created_at) VALUES(?,?,?,?,?,?,?,?,?,?)",(stable_id("finding",vid,idx),vid,f.validator,f.severity,f.code,f.object_type,f.object_id,f.message,canonical_json(f.details or {}),completed))
                self._append_event(con,store_result_for_run,"validation_completed",{"validation_run_id":vid,"passed":report["passed"],"blocking_count":blocking,"warning_count":warnings})
        return report

    def export(self, output: Path) -> dict[str, str]:
        output.mkdir(parents=True, exist_ok=True)
        exports={}
        with self.connection() as con:
            for view in ("canonical_graph","provisional_graph","full_research_graph","contradiction_graph"):
                rows=[dict(r) for r in con.execute(f"SELECT * FROM {view} ORDER BY 1")]
                path=output/f"{view}.jsonl"; path.write_text("".join(canonical_json(r)+"\n" for r in rows),encoding="utf-8"); exports[path.name]=sha256_file(path)
                if view!="contradiction_graph":
                    csvpath=output/f"{view}.csv"
                    keys=list(rows[0]) if rows else ["claim_version_id","claim_id","version_no","subject_entity_version_id","predicate","object_entity_version_id","object_literal","state","review_tier"]
                    with csvpath.open("w",encoding="utf-8",newline="") as f:
                        w=csv.DictWriter(f,fieldnames=keys,extrasaction="ignore"); w.writeheader(); w.writerows(rows)
                    exports[csvpath.name]=sha256_file(csvpath)
            edges=[dict(r) for r in con.execute("SELECT * FROM canonical_graph ORDER BY claim_version_id")]
            referenced = {e["subject_entity_version_id"] for e in edges} | {
                e["object_entity_version_id"] for e in edges if e["object_entity_version_id"] is not None}
            nodes=[dict(r) for r in con.execute("SELECT * FROM entity_versions ORDER BY entity_version_id")
                   if r["entity_version_id"] in referenced or
                   con.execute("SELECT 1 FROM current_entity_versions WHERE entity_version_id=?",
                               (r["entity_version_id"],)).fetchone()]
            graph=output/"canonical_graph.graphml"
            lines=['<?xml version="1.0" encoding="UTF-8"?>','<graphml xmlns="http://graphml.graphdrawing.org/xmlns">','<graph id="OCSA-canonical" edgedefault="directed">']
            for n in nodes: lines.append(f'<node id="{escape(n["entity_version_id"])}"><data key="label">{escape(n["canonical_label"])}</data><data key="type">{escape(n["entity_type"])}</data></node>')
            for e in edges:
                target=e["object_entity_version_id"] or "literal:"+sha256_text(e["object_literal"] or "")[:16]
                if e["object_entity_version_id"] is None: lines.append(f'<node id="{escape(target)}"><data key="label">{escape(e["object_literal"] or "")}</data><data key="type">literal</data></node>')
                lines.append(f'<edge id="{escape(e["claim_version_id"])}" source="{escape(e["subject_entity_version_id"])}" target="{escape(target)}"><data key="predicate">{escape(e["predicate"])}</data></edge>')
            lines.extend(['</graph>','</graphml>']); graph.write_text("\n".join(lines)+"\n",encoding="utf-8"); exports[graph.name]=sha256_file(graph)
            legacy_graph = output / "atlas.graphml"
            legacy_graph.write_bytes(graph.read_bytes()); exports[legacy_graph.name]=sha256_file(legacy_graph)
            for table in ("current_source_versions","current_entity_versions","evidence_spans",
                          "current_evidence_spans","claim_reviews","current_claim_reviews",
                          "source_versions","entity_versions","claim_versions","claim_evidence",
                          "source_authenticity_checks","source_files"):
                path=output/f"{table}.jsonl"; rows=[dict(r) for r in con.execute(f"SELECT * FROM {table} ORDER BY 1")]; path.write_text("".join(canonical_json(r)+"\n" for r in rows),encoding="utf-8"); exports[path.name]=sha256_file(path)
            for name, table in (("sources","current_source_versions"),("entities","current_entity_versions"),
                                ("claims","current_claim_versions"),("contradictions","contradiction_graph"),
                                ("open_questions","question_versions"),
                                ("metadata","metadata")):
                path=output/f"{name}.jsonl"; rows=[dict(r) for r in con.execute(f"SELECT * FROM {table} ORDER BY 1")]
                path.write_text("".join(canonical_json(r)+"\n" for r in rows),encoding="utf-8"); exports[path.name]=sha256_file(path)
        return exports

    def graph_diff(self, before_db: Path, after_db: Path, *, run_id: str, output: Path, removal_limit: float = 0.25) -> dict[str, Any]:
        def current(db: Path):
            con=sqlite3.connect(db); con.row_factory=sqlite3.Row
            try:
                nodes={r[0]:r[1] for r in con.execute("SELECT entity_id,entity_version_id FROM current_entity_versions")}
                edges={r[0]:tuple(r) for r in con.execute("SELECT claim_version_id,subject_entity_version_id,predicate,object_entity_version_id,object_literal,state FROM current_claim_versions")}
                canon={r[0] for r in con.execute("SELECT claim_version_id FROM canonical_graph")}
                return nodes,edges,canon
            finally: con.close()
        bn,be,bc=current(before_db); an,ae,ac=current(after_db)
        removed_nodes=set(bn)-set(an); removed_edges=set(be)-set(ae)
        halt=bool(len(removed_nodes)>10 or len(removed_edges)>20 or (bool(bn) and len(removed_nodes)/len(bn)>removal_limit) or (bool(be) and len(removed_edges)/len(be)>removal_limit))
        changed_nodes={eid for eid in set(bn)&set(an) if bn[eid]!=an[eid]}
        result={"before_database_sha256":sha256_file(before_db),"after_database_sha256":sha256_file(after_db),"nodes_added":len(set(an)-set(bn)),"nodes_removed":len(removed_nodes),"nodes_changed":len(changed_nodes),"edges_added":len(set(ae)-set(be)),"edges_removed":len(removed_edges),"edges_changed":0,"status_changes":sum(1 for k in set(be)&set(ae) if be[k][-1]!=ae[k][-1]),"canonical_edges_added":len(ac-bc),"canonical_edges_removed":len(bc-ac),"foundational_changes":0,"mass_change_halt":bool(halt),"details":{"node_ids_added":sorted(set(an)-set(bn)),"node_ids_changed":sorted(changed_nodes),"edge_ids_added":sorted(set(ae)-set(be))}}
        write_json(output,result)
        with self.connection(write=True) as con:
            con.execute("""INSERT INTO graph_diffs(graph_diff_id,run_id,before_database_sha256,after_database_sha256,nodes_added,nodes_removed,nodes_changed,edges_added,edges_removed,edges_changed,status_changes,foundational_changes,mass_change_halt,details_json,created_at) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",(stable_id("diff",run_id,result["before_database_sha256"],result["after_database_sha256"]),run_id,result["before_database_sha256"],result["after_database_sha256"],result["nodes_added"],result["nodes_removed"],result["nodes_changed"],result["edges_added"],result["edges_removed"],0,result["status_changes"],0,int(halt),canonical_json(result["details"]),utc_now()))
            self._append_event(con,run_id,"graph_diff_generated",result)
        return result


def build_parser() -> argparse.ArgumentParser:
    p=argparse.ArgumentParser(description="OCSA provenance-first store")
    p.add_argument("--db",type=Path,default=Path("atlas.db")); p.add_argument("--schema",type=Path,default=Path("schema.sql")); p.add_argument("--root",type=Path,default=Path("."))
    sub=p.add_subparsers(dest="command",required=True)
    sub.add_parser("init"); sub.add_parser("stats")
    v=sub.add_parser("validate"); v.add_argument("--output",type=Path); v.add_argument("--store-for-run")
    s=sub.add_parser("snapshot"); s.add_argument("--run-id",required=True); s.add_argument("--phase",required=True); s.add_argument("--output",type=Path,required=True)
    i=sub.add_parser("ingest-module1"); i.add_argument("--run-id",required=True); i.add_argument("--run-dir",type=Path,required=True)
    e=sub.add_parser("export"); e.add_argument("--output",type=Path,default=Path("exports"))
    g=sub.add_parser("graph-diff"); g.add_argument("--run-id",required=True); g.add_argument("--before",type=Path,required=True); g.add_argument("--after",type=Path,required=True); g.add_argument("--output",type=Path,required=True)
    return p


def main() -> int:
    args=build_parser().parse_args(); root=args.root.resolve(); store=AtlasStore(args.db.resolve(),args.schema.resolve(),root)
    if args.command=="init": store.init(); result={"initialized":str(store.db_path),"schema_version":SCHEMA_VERSION}
    elif args.command=="stats": result=store.stats()
    elif args.command=="validate":
        result=store.validate(store_result_for_run=args.store_for_run)
        if args.output: write_json(args.output,result)
    elif args.command=="snapshot": result=store.snapshot(args.run_id,args.phase,args.output.resolve())
    elif args.command=="ingest-module1": result=store.ingest_module1_staging(args.run_dir.resolve(),run_id=args.run_id)
    elif args.command=="export": result=store.export(args.output.resolve())
    elif args.command=="graph-diff": result=store.graph_diff(args.before.resolve(),args.after.resolve(),run_id=args.run_id,output=args.output.resolve())
    else: raise AssertionError(args.command)
    print(json.dumps(result,indent=2,sort_keys=True,ensure_ascii=False))
    return 0 if not isinstance(result,dict) or result.get("passed",True) else 1

if __name__=="__main__": raise SystemExit(main())
