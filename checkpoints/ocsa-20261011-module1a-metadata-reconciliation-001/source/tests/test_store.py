from __future__ import annotations

import hashlib
import json
import shutil
import sqlite3
import tempfile
import unittest
from pathlib import Path
import sys

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'src'))
from ocsa_store import AtlasStore, canonical_json, sha256_file, sha256_text

class OCSAHardenedTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory(); self.root=Path(self.tmp.name)
        self.db=self.root/'atlas.db'; self.store=AtlasStore(self.db,ROOT/'schema.sql',self.root); self.store.init()
        self.run='test-run'; self.store.create_run(run_id=self.run,module='test',scope='test infrastructure')
    def tearDown(self): self.tmp.cleanup()
    def con(self):
        c=sqlite3.connect(self.db); c.row_factory=sqlite3.Row; c.execute('PRAGMA foreign_keys=ON'); return c
    def seed_entity(self,eid='E1',etype='gene'):
        with self.store.connection(write=True) as c:
            c.execute('INSERT INTO entities VALUES(?,?,?)',(eid,self.run,'2026-01-01T00:00:00+00:00'))
            c.execute('INSERT INTO entity_versions(entity_version_id,entity_id,version_no,entity_type,canonical_label,status,change_reason,created_in_run,created_at) VALUES(?,?,?,?,?,?,?,?,?)',(eid+'-v1',eid,1,etype,eid,'proposed','test',self.run,'2026-01-01T00:00:00+00:00'))
    def test_clean_database_validates(self): self.assertTrue(self.store.validate()['passed'])
    def test_stale_canonical_view_is_blocking(self):
        with self.store.connection(write=True) as c:
            c.execute('DROP VIEW canonical_graph')
            c.execute('CREATE VIEW canonical_graph AS SELECT * FROM current_claim_versions')
        self.assertIn('STALE_CANONICAL_VIEW',{x['code'] for x in self.store.validate()['findings']})
    def test_claim_defaults_to_proposed(self):
        self.seed_entity()
        with self.store.connection(write=True) as c:
            c.execute('INSERT INTO claims VALUES(?,?,?)',('C1',self.run,'2026-01-01T00:00:00+00:00'))
            c.execute("INSERT INTO claim_versions(claim_version_id,claim_id,version_no,subject_entity_version_id,predicate,object_literal,change_reason,created_in_run,created_at) VALUES(?,?,?,?,?,?,?,?,?)",('C1-v1','C1',1,'E1-v1','HAS_APPROVED_GENE_IDENTITY','{}','test',self.run,'2026-01-01T00:00:00+00:00'))
            self.assertEqual(c.execute('SELECT state FROM claim_versions').fetchone()[0],'proposed')
    def test_new_claim_cannot_start_accepted(self):
        self.seed_entity()
        with self.assertRaises(sqlite3.IntegrityError), self.store.connection(write=True) as c:
            c.execute('INSERT INTO claims VALUES(?,?,?)',('C1',self.run,'2026-01-01T00:00:00+00:00'))
            c.execute("INSERT INTO claim_versions(claim_version_id,claim_id,version_no,subject_entity_version_id,predicate,object_literal,state,change_reason,created_in_run,created_at) VALUES(?,?,?,?,?,?,?,?,?,?)",('C1-v1','C1',1,'E1-v1','HAS_APPROVED_GENE_IDENTITY','{}','accepted','test',self.run,'2026-01-01T00:00:00+00:00'))
    def test_append_only_rejects_update_delete(self):
        self.seed_entity()
        with self.assertRaises(sqlite3.DatabaseError), self.store.connection(write=True) as c: c.execute("UPDATE entity_versions SET canonical_label='x'")
        with self.assertRaises(sqlite3.DatabaseError), self.store.connection(write=True) as c: c.execute('DELETE FROM entity_versions')
    def test_excerpt_hash_corruption_detected(self):
        with self.store.connection(write=True) as c:
            c.execute('INSERT INTO source_records VALUES(?,?,?)',('S1',self.run,'2026-01-01T00:00:00+00:00'))
            c.execute("INSERT INTO source_versions(source_version_id,source_id,version_no,title,source_type,access_status,change_reason,created_in_run,created_at) VALUES(?,?,?,?,?,?,?,?,?)",('S1-v1','S1',1,'t','database','public','test',self.run,'2026-01-01T00:00:00+00:00'))
            c.execute("INSERT INTO evidence_spans(evidence_span_id,source_version_id,excerpt,excerpt_sha256,evidence_role,extraction_method,created_in_run,created_at) VALUES(?,?,?,?,?,?,?,?)",('EV1','S1-v1','abc','0'*64,'direct','manual',self.run,'2026-01-01T00:00:00+00:00'))
        self.assertIn('EXCERPT_HASH_MISMATCH',{x['code'] for x in self.store.validate()['findings']})
    def test_source_file_tampering_detected(self):
        p=self.root/'sources'/'x.txt'; p.parent.mkdir(); p.write_text('abc'); digest=sha256_file(p)
        with self.store.connection(write=True) as c: c.execute('INSERT INTO source_files VALUES(?,?,?,?,?,?,?,?,?)',(digest,'sources/x.txt','text/plain',3,'open','public','2026-01-01',self.run,'2026-01-01'))
        p.write_text('def')
        self.assertIn('SOURCE_FILE_HASH_MISMATCH',{x['code'] for x in self.store.validate()['findings']})
    def test_invalid_semantic_pattern_detected(self):
        self.seed_entity('R','receptor_target')
        with self.store.connection(write=True) as c:
            c.execute('INSERT INTO claims VALUES(?,?,?)',('C',self.run,'2026-01-01'))
            c.execute("INSERT INTO claim_versions(claim_version_id,claim_id,version_no,subject_entity_version_id,predicate,object_literal,change_reason,created_in_run,created_at) VALUES(?,?,?,?,?,?,?,?,?)",('C-v1','C',1,'R-v1','PROJECTS_TO','x','test',self.run,'2026-01-01'))
        self.assertIn('INVALID_SEMANTIC_PATTERN',{x['code'] for x in self.store.validate()['findings']})
    def test_causal_overstatement_detected(self):
        self.seed_entity('G','gene')
        with self.store.connection(write=True) as c:
            c.execute("INSERT OR IGNORE INTO allowed_semantic_patterns VALUES('gene','CAUSES','literal')")
            c.execute('INSERT INTO claims VALUES(?,?,?)',('C',self.run,'2026-01-01'))
            c.execute("INSERT INTO claim_versions(claim_version_id,claim_id,version_no,subject_entity_version_id,predicate,object_literal,change_reason,created_in_run,created_at) VALUES(?,?,?,?,?,?,?,?,?)",('C-v1','C',1,'G-v1','CAUSES','x','test',self.run,'2026-01-01'))
        self.assertIn('CAUSAL_OVERSTATEMENT',{x['code'] for x in self.store.validate()['findings']})
    def test_event_hash_chain_tampering_detected(self):
        # Drop protection only in isolated corruption fixture.
        c=self.con(); c.execute('DROP TRIGGER no_update_run_events'); c.execute("UPDATE run_events SET payload_json='{}'"); c.commit(); c.close()
        self.assertIn('EVENT_HASH_CHAIN',{x['code'] for x in self.store.validate()['findings']})
    def test_snapshot_tampering_detected(self):
        p=self.root/'snapshots'/'x.db'; self.store.snapshot(self.run,'pre_run',p); p.write_bytes(b'bad')
        self.assertIn('SNAPSHOT_HASH_MISMATCH',{x['code'] for x in self.store.validate()['findings']})
    def test_canonical_graph_excludes_proposed(self):
        self.seed_entity();
        with self.store.connection(write=True) as c:
            c.execute('INSERT INTO claims VALUES(?,?,?)',('C',self.run,'2026-01-01'))
            c.execute("INSERT INTO claim_versions(claim_version_id,claim_id,version_no,subject_entity_version_id,predicate,object_literal,change_reason,created_in_run,created_at) VALUES(?,?,?,?,?,?,?,?,?)",('C-v1','C',1,'E1-v1','HAS_APPROVED_GENE_IDENTITY','{}','test',self.run,'2026-01-01'))
            self.assertEqual(c.execute('SELECT count(*) FROM canonical_graph').fetchone()[0],0)
    def test_accepted_requires_every_gate(self):
        self.seed_entity();
        with self.store.connection(write=True) as c:
            c.execute('INSERT INTO claims VALUES(?,?,?)',('C',self.run,'2026-01-01'))
            c.execute("INSERT INTO claim_versions(claim_version_id,claim_id,version_no,subject_entity_version_id,predicate,object_literal,state,review_tier,context_json,change_reason,created_in_run,created_at) VALUES(?,?,?,?,?,?,?,?,?,?,?,?)",('C-v1','C',1,'E1-v1','HAS_APPROVED_GENE_IDENTITY','{}','proposed',0,'{"species":"human"}','test',self.run,'2026-01-01'))
            c.execute("INSERT INTO claim_versions(claim_version_id,claim_id,version_no,supersedes_claim_version_id,subject_entity_version_id,predicate,object_literal,state,review_tier,context_json,change_reason,created_in_run,created_at) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?)",('C-v2','C',2,'C-v1','E1-v1','HAS_APPROVED_GENE_IDENTITY','{}','accepted',2,'{"species":"human"}','test promotion',self.run,'2026-01-02'))
        report=self.store.validate(); self.assertIn('ACCEPTED_NOT_CANONICAL_ELIGIBLE',{x['code'] for x in report['findings']})
    def test_exports_byte_deterministic(self):
        a=self.root/'a'; b=self.root/'b'; self.store.export(a); self.store.export(b)
        self.assertEqual({p.name:p.read_bytes() for p in a.iterdir()},{p.name:p.read_bytes() for p in b.iterdir()})
    def test_graph_diff_halts_mass_deletion(self):
        self.seed_entity('A'); self.seed_entity('B')
        before=self.root/'before.db'; self.store.snapshot(self.run,'pre_run',before)
        # Build a valid after DB with no nodes independently.
        after=self.root/'after.db'; s=AtlasStore(after,ROOT/'schema.sql',self.root); s.init(); s.create_run(run_id='after',module='test',scope='test')
        result=self.store.graph_diff(before,after,run_id=self.run,output=self.root/'diff.json',removal_limit=0.25)
        self.assertTrue(result['mass_change_halt'])
    def test_graph_diff_classifies_entity_supersession_as_change(self):
        self.seed_entity('E')
        before=self.root/'before.db'; self.store.snapshot(self.run,'pre_run',before)
        with self.store.connection(write=True) as c:
            c.execute("INSERT INTO entity_versions(entity_version_id,entity_id,version_no,supersedes_entity_version_id,entity_type,canonical_label,status,change_reason,created_in_run,created_at) VALUES(?,?,?,?,?,?,?,?,?,?)",('E-v2','E',2,'E-v1','gene','E','proposed','metadata correction',self.run,'2026-01-02'))
        result=self.store.graph_diff(before,self.db,run_id=self.run,output=self.root/'diff.json')
        self.assertEqual((result['nodes_added'],result['nodes_removed'],result['nodes_changed']),(0,0,1))
        self.assertFalse(result['mass_change_halt'])
    def test_database_header_corruption_returns_finding(self):
        bad=self.root/'bad.db'; bad.write_bytes(b'not sqlite'); s=AtlasStore(bad,ROOT/'schema.sql',self.root)
        self.assertIn('DATABASE_ERROR',{x['code'] for x in s.validate()['findings']})
    def test_module1_staging_ingestion(self):
        run='module1'; self.store.create_run(run_id=run,module='Module 1',scope='identifiers')
        result=self.store.ingest_module1_staging(ROOT/'runs'/'ocsa-20260725-module1-receptor-identifiers-001',run_id=run)
        self.assertEqual(result['claims'],12); self.assertEqual(self.store.stats()['canonical_graph'],0)
        self.assertTrue(self.store.validate()['passed'])

    def test_superseded_review_cannot_authorize_canonical_claim(self):
        self.seed_entity('E')
        source_file = self.root/'source.txt'; source_file.write_text('abc'); digest=sha256_file(source_file)
        with self.store.connection(write=True) as c:
            c.execute('INSERT INTO source_files VALUES(?,?,?,?,?,?,?,?,?)',(digest,'source.txt','text/plain',3,'open','public','2026-01-01',self.run,'2026-01-01'))
            c.execute('INSERT INTO source_records VALUES(?,?,?)',('S',self.run,'2026-01-01'))
            c.execute("INSERT INTO source_versions(source_version_id,source_id,version_no,title,source_type,access_status,source_file_sha256,change_reason,created_in_run,created_at) VALUES(?,?,?,?,?,?,?,?,?,?)",('S-v1','S',1,'test','database','public',digest,'test',self.run,'2026-01-01'))
            c.execute("INSERT INTO source_authenticity_checks(check_id,source_version_id,resolution_status,checked_in_run,checked_at) VALUES(?,?,?,?,?)",('A','S-v1','pass',self.run,'2026-01-01'))
            c.execute("INSERT INTO evidence_spans(evidence_span_id,source_version_id,source_file_sha256,excerpt,excerpt_sha256,evidence_role,extraction_method,created_in_run,created_at) VALUES(?,?,?,?,?,?,?,?,?)",('EV','S-v1',digest,'abc',sha256_text('abc'),'direct','manual',self.run,'2026-01-01'))
            c.execute("INSERT INTO entity_versions(entity_version_id,entity_id,version_no,supersedes_entity_version_id,entity_type,canonical_label,status,change_reason,created_in_run,created_at) VALUES(?,?,?,?,?,?,?,?,?,?)",('E-v2','E',2,'E-v1','gene','E','proposed','metadata revision',self.run,'2026-01-02'))
            c.execute('INSERT INTO claims VALUES(?,?,?)',('C',self.run,'2026-01-01'))
            c.execute("INSERT INTO claim_versions(claim_version_id,claim_id,version_no,subject_entity_version_id,predicate,object_literal,context_json,change_reason,created_in_run,created_at) VALUES(?,?,?,?,?,?,?,?,?,?)",('C-v1','C',1,'E-v1','HAS_APPROVED_GENE_IDENTITY','{}','{"species":"human"}','seed',self.run,'2026-01-01'))
            c.execute("INSERT INTO claim_versions(claim_version_id,claim_id,version_no,supersedes_claim_version_id,subject_entity_version_id,predicate,object_literal,context_json,state,review_tier,change_reason,created_in_run,created_at) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?)",('C-v2','C',2,'C-v1','E-v1','HAS_APPROVED_GENE_IDENTITY','{}','{"species":"human"}','accepted',2,'test',self.run,'2026-01-02'))
            c.execute('INSERT INTO claim_evidence VALUES(?,?,?)',('C-v2','EV','supporting'))
            c.execute("INSERT INTO claim_reviews(review_id,claim_version_id,review_pass,reviewer_class,independent,result,reviewed_in_run,reviewed_at) VALUES(?,?,?,?,?,?,?,?)",('R','C-v2',2,'independent',1,'agree',self.run,'2026-01-02'))
            self.assertEqual(c.execute('SELECT count(*) FROM canonical_graph').fetchone()[0],1)
        graph = self.root/'exports'/'canonical_graph.graphml'; self.store.export(graph.parent)
        self.assertIn('node id="E-v1"',graph.read_text())
        self.assertIn('node id="E-v2"',graph.read_text())
        self.assertIn('source="E-v1"',graph.read_text())
        with self.store.connection(write=True) as c:
            c.execute("INSERT INTO claim_reviews(review_id,version_no,supersedes_review_id,claim_version_id,review_pass,reviewer_class,independent,result,reviewed_in_run,reviewed_at) VALUES(?,?,?,?,?,?,?,?,?,?)",('R-v2',2,'R','C-v2',2,'independent',1,'disagree',self.run,'2026-01-03'))
            self.assertEqual(c.execute('SELECT count(*) FROM canonical_graph').fetchone()[0],0)

if __name__=='__main__': unittest.main(verbosity=2)
