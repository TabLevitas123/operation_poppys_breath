PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;
PRAGMA synchronous = FULL;

CREATE TABLE metadata (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
) WITHOUT ROWID;

CREATE TABLE research_runs (
  run_id TEXT PRIMARY KEY,
  module TEXT NOT NULL,
  scope TEXT NOT NULL,
  status TEXT NOT NULL CHECK(status IN ('staging','validated','released','failed','rolled_back')),
  parent_release TEXT,
  parent_database_sha256 TEXT,
  prompt_sha256 TEXT,
  search_protocol_version TEXT,
  model_json TEXT NOT NULL DEFAULT '{}',
  tool_versions_json TEXT NOT NULL DEFAULT '{}',
  started_at TEXT NOT NULL,
  completed_at TEXT,
  before_database_sha256 TEXT,
  after_database_sha256 TEXT,
  created_at TEXT NOT NULL
);

CREATE TABLE run_events (
  event_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL REFERENCES research_runs(run_id),
  sequence_no INTEGER NOT NULL CHECK(sequence_no > 0),
  event_type TEXT NOT NULL,
  payload_json TEXT NOT NULL DEFAULT '{}',
  previous_event_hash TEXT,
  event_hash TEXT NOT NULL CHECK(length(event_hash)=64),
  created_at TEXT NOT NULL,
  UNIQUE(run_id, sequence_no)
);

CREATE TABLE source_records (
  source_id TEXT PRIMARY KEY,
  created_in_run TEXT NOT NULL REFERENCES research_runs(run_id),
  created_at TEXT NOT NULL
);

CREATE TABLE source_files (
  sha256 TEXT PRIMARY KEY CHECK(length(sha256)=64),
  immutable_path TEXT NOT NULL UNIQUE,
  mime_type TEXT,
  size_bytes INTEGER NOT NULL CHECK(size_bytes >= 0),
  license_status TEXT,
  access_status TEXT NOT NULL,
  retrieved_at TEXT NOT NULL,
  created_in_run TEXT NOT NULL REFERENCES research_runs(run_id),
  created_at TEXT NOT NULL
);

CREATE TABLE source_versions (
  source_version_id TEXT PRIMARY KEY,
  source_id TEXT NOT NULL REFERENCES source_records(source_id),
  version_no INTEGER NOT NULL CHECK(version_no > 0),
  supersedes_source_version_id TEXT REFERENCES source_versions(source_version_id),
  title TEXT NOT NULL,
  authors_json TEXT NOT NULL DEFAULT '[]',
  journal_or_repository TEXT,
  publication_year INTEGER,
  doi TEXT,
  pmid TEXT,
  pmcid TEXT,
  trial_id TEXT,
  patent_id TEXT,
  original_url TEXT,
  resolved_url TEXT,
  source_type TEXT NOT NULL,
  species TEXT,
  publication_status TEXT NOT NULL DEFAULT 'published',
  correction_retraction_status TEXT NOT NULL DEFAULT 'none_known',
  access_status TEXT NOT NULL,
  source_file_sha256 TEXT REFERENCES source_files(sha256),
  extraction_status TEXT NOT NULL DEFAULT 'not_started',
  metadata_json TEXT NOT NULL DEFAULT '{}',
  change_reason TEXT NOT NULL,
  created_in_run TEXT NOT NULL REFERENCES research_runs(run_id),
  created_at TEXT NOT NULL,
  UNIQUE(source_id, version_no),
  CHECK((version_no=1 AND supersedes_source_version_id IS NULL) OR version_no>1)
);

CREATE TABLE source_authenticity_checks (
  check_id TEXT PRIMARY KEY,
  source_version_id TEXT NOT NULL REFERENCES source_versions(source_version_id),
  identifier_type TEXT,
  identifier_value TEXT,
  title_match INTEGER CHECK(title_match IN (0,1)),
  author_match INTEGER CHECK(author_match IN (0,1)),
  venue_match INTEGER CHECK(venue_match IN (0,1)),
  year_match INTEGER CHECK(year_match IN (0,1)),
  resolution_status TEXT NOT NULL CHECK(resolution_status IN ('pass','fail','partial','not_applicable')),
  details_json TEXT NOT NULL DEFAULT '{}',
  checked_in_run TEXT NOT NULL REFERENCES research_runs(run_id),
  checked_at TEXT NOT NULL
);

CREATE TABLE paper_dossiers (
  dossier_id TEXT PRIMARY KEY,
  source_version_id TEXT NOT NULL REFERENCES source_versions(source_version_id),
  dossier_json TEXT NOT NULL,
  dossier_sha256 TEXT NOT NULL CHECK(length(dossier_sha256)=64),
  created_in_run TEXT NOT NULL REFERENCES research_runs(run_id),
  created_at TEXT NOT NULL
);

CREATE TABLE entities (
  entity_id TEXT PRIMARY KEY,
  created_in_run TEXT NOT NULL REFERENCES research_runs(run_id),
  created_at TEXT NOT NULL
);

CREATE TABLE entity_versions (
  entity_version_id TEXT PRIMARY KEY,
  entity_id TEXT NOT NULL REFERENCES entities(entity_id),
  version_no INTEGER NOT NULL CHECK(version_no > 0),
  supersedes_entity_version_id TEXT REFERENCES entity_versions(entity_version_id),
  entity_type TEXT NOT NULL,
  canonical_label TEXT NOT NULL,
  species TEXT,
  identifiers_json TEXT NOT NULL DEFAULT '{}',
  aliases_json TEXT NOT NULL DEFAULT '[]',
  chromosomal_location TEXT,
  metadata_json TEXT NOT NULL DEFAULT '{}',
  definition TEXT,
  status TEXT NOT NULL DEFAULT 'proposed' CHECK(status IN ('proposed','reviewed','accepted','deprecated','rejected','merged','split')),
  change_reason TEXT NOT NULL,
  created_in_run TEXT NOT NULL REFERENCES research_runs(run_id),
  created_at TEXT NOT NULL,
  UNIQUE(entity_id, version_no),
  CHECK((version_no=1 AND supersedes_entity_version_id IS NULL) OR version_no>1)
);

CREATE TABLE evidence_spans (
  evidence_span_id TEXT PRIMARY KEY,
  version_no INTEGER NOT NULL DEFAULT 1 CHECK(version_no > 0),
  supersedes_evidence_span_id TEXT REFERENCES evidence_spans(evidence_span_id),
  change_reason TEXT,
  source_version_id TEXT NOT NULL REFERENCES source_versions(source_version_id),
  source_file_sha256 TEXT REFERENCES source_files(sha256),
  page_locator TEXT,
  section_locator TEXT,
  paragraph_locator TEXT,
  figure_locator TEXT,
  table_locator TEXT,
  supplement_locator TEXT,
  character_start INTEGER,
  character_end INTEGER,
  excerpt TEXT NOT NULL,
  excerpt_sha256 TEXT NOT NULL CHECK(length(excerpt_sha256)=64),
  evidence_role TEXT NOT NULL,
  extraction_method TEXT NOT NULL,
  reported_observation TEXT,
  authors_interpretation TEXT,
  curator_synthesis TEXT,
  context_json TEXT NOT NULL DEFAULT '{}',
  created_in_run TEXT NOT NULL REFERENCES research_runs(run_id),
  created_at TEXT NOT NULL
);

CREATE UNIQUE INDEX one_successor_per_evidence_span ON evidence_spans(supersedes_evidence_span_id)
WHERE supersedes_evidence_span_id IS NOT NULL;

CREATE TABLE claims (
  claim_id TEXT PRIMARY KEY,
  created_in_run TEXT NOT NULL REFERENCES research_runs(run_id),
  created_at TEXT NOT NULL
);

CREATE TABLE claim_versions (
  claim_version_id TEXT PRIMARY KEY,
  claim_id TEXT NOT NULL REFERENCES claims(claim_id),
  version_no INTEGER NOT NULL CHECK(version_no > 0),
  supersedes_claim_version_id TEXT REFERENCES claim_versions(claim_version_id),
  subject_entity_version_id TEXT NOT NULL REFERENCES entity_versions(entity_version_id),
  predicate TEXT NOT NULL,
  object_entity_version_id TEXT REFERENCES entity_versions(entity_version_id),
  object_literal TEXT,
  polarity TEXT NOT NULL DEFAULT 'positive' CHECK(polarity IN ('positive','negative','null','mixed')),
  causal_strength TEXT NOT NULL DEFAULT 'descriptive',
  context_json TEXT NOT NULL DEFAULT '{}',
  numerical_result_json TEXT NOT NULL DEFAULT '{}',
  state TEXT NOT NULL DEFAULT 'proposed' CHECK(state IN ('proposed','source_verified','evidence_anchored','extraction_verified','reviewed','accepted','disputed','rejected','superseded','retracted','duplicate','insufficient_evidence')),
  review_tier INTEGER NOT NULL DEFAULT 0 CHECK(review_tier BETWEEN 0 AND 4),
  change_reason TEXT NOT NULL,
  created_in_run TEXT NOT NULL REFERENCES research_runs(run_id),
  created_at TEXT NOT NULL,
  UNIQUE(claim_id, version_no),
  CHECK((object_entity_version_id IS NOT NULL AND object_literal IS NULL) OR (object_entity_version_id IS NULL AND object_literal IS NOT NULL)),
  CHECK((version_no=1 AND supersedes_claim_version_id IS NULL AND state='proposed') OR version_no>1)
);

CREATE TABLE claim_evidence (
  claim_version_id TEXT NOT NULL REFERENCES claim_versions(claim_version_id),
  evidence_span_id TEXT NOT NULL REFERENCES evidence_spans(evidence_span_id),
  evidence_weight TEXT NOT NULL DEFAULT 'supporting',
  PRIMARY KEY(claim_version_id, evidence_span_id)
) WITHOUT ROWID;

CREATE TABLE claim_reviews (
  review_id TEXT PRIMARY KEY,
  version_no INTEGER NOT NULL DEFAULT 1 CHECK(version_no > 0),
  supersedes_review_id TEXT REFERENCES claim_reviews(review_id),
  recorded_in_run TEXT REFERENCES research_runs(run_id),
  change_reason TEXT,
  claim_version_id TEXT NOT NULL REFERENCES claim_versions(claim_version_id),
  review_pass INTEGER NOT NULL CHECK(review_pass IN (1,2)),
  reviewer_class TEXT NOT NULL,
  independent INTEGER NOT NULL CHECK(independent IN (0,1)),
  result TEXT NOT NULL CHECK(result IN ('agree','disagree','needs_adjudication','not_reviewed')),
  checks_json TEXT NOT NULL DEFAULT '{}',
  notes TEXT,
  reviewed_in_run TEXT NOT NULL REFERENCES research_runs(run_id),
  reviewed_at TEXT NOT NULL
);

CREATE UNIQUE INDEX one_successor_per_review ON claim_reviews(supersedes_review_id)
WHERE supersedes_review_id IS NOT NULL;

CREATE TABLE contradictions (
  contradiction_id TEXT PRIMARY KEY,
  created_in_run TEXT NOT NULL REFERENCES research_runs(run_id),
  created_at TEXT NOT NULL
);

CREATE TABLE contradiction_versions (
  contradiction_version_id TEXT PRIMARY KEY,
  contradiction_id TEXT NOT NULL REFERENCES contradictions(contradiction_id),
  version_no INTEGER NOT NULL CHECK(version_no>0),
  supersedes_contradiction_version_id TEXT REFERENCES contradiction_versions(contradiction_version_id),
  claim_a_id TEXT NOT NULL REFERENCES claims(claim_id),
  claim_b_id TEXT NOT NULL REFERENCES claims(claim_id),
  evidence_context_json TEXT NOT NULL DEFAULT '{}',
  possible_explanations_json TEXT NOT NULL DEFAULT '[]',
  replication_status TEXT NOT NULL DEFAULT 'not_assessed',
  adjudication_status TEXT NOT NULL DEFAULT 'open',
  adjudication_notes TEXT,
  change_reason TEXT NOT NULL,
  created_in_run TEXT NOT NULL REFERENCES research_runs(run_id),
  created_at TEXT NOT NULL,
  UNIQUE(contradiction_id, version_no),
  CHECK(claim_a_id<>claim_b_id)
);

CREATE TABLE open_questions (
  question_id TEXT PRIMARY KEY,
  created_in_run TEXT NOT NULL REFERENCES research_runs(run_id),
  created_at TEXT NOT NULL
);

CREATE TABLE question_versions (
  question_version_id TEXT PRIMARY KEY,
  question_id TEXT NOT NULL REFERENCES open_questions(question_id),
  version_no INTEGER NOT NULL CHECK(version_no>0),
  supersedes_question_version_id TEXT REFERENCES question_versions(question_version_id),
  question TEXT NOT NULL,
  rationale TEXT,
  priority TEXT NOT NULL DEFAULT 'medium',
  status TEXT NOT NULL DEFAULT 'open',
  linked_entity_ids_json TEXT NOT NULL DEFAULT '[]',
  change_reason TEXT NOT NULL,
  created_in_run TEXT NOT NULL REFERENCES research_runs(run_id),
  created_at TEXT NOT NULL,
  UNIQUE(question_id,version_no)
);

CREATE TABLE allowed_semantic_patterns (
  subject_type TEXT NOT NULL,
  predicate TEXT NOT NULL,
  object_type TEXT NOT NULL,
  PRIMARY KEY(subject_type,predicate,object_type)
) WITHOUT ROWID;

CREATE TABLE validation_runs (
  validation_run_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL REFERENCES research_runs(run_id),
  validator_version TEXT NOT NULL,
  database_sha256 TEXT,
  passed INTEGER NOT NULL CHECK(passed IN (0,1)),
  blocking_count INTEGER NOT NULL DEFAULT 0,
  warning_count INTEGER NOT NULL DEFAULT 0,
  started_at TEXT NOT NULL,
  completed_at TEXT NOT NULL
);

CREATE TABLE validation_findings (
  finding_id TEXT PRIMARY KEY,
  validation_run_id TEXT NOT NULL REFERENCES validation_runs(validation_run_id),
  validator_name TEXT NOT NULL,
  severity TEXT NOT NULL CHECK(severity IN ('blocking','warning','info')),
  code TEXT NOT NULL,
  object_type TEXT,
  object_id TEXT,
  message TEXT NOT NULL,
  details_json TEXT NOT NULL DEFAULT '{}',
  created_at TEXT NOT NULL
);

CREATE TABLE graph_diffs (
  graph_diff_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL REFERENCES research_runs(run_id),
  before_database_sha256 TEXT,
  after_database_sha256 TEXT,
  nodes_added INTEGER NOT NULL DEFAULT 0,
  nodes_removed INTEGER NOT NULL DEFAULT 0,
  nodes_changed INTEGER NOT NULL DEFAULT 0,
  edges_added INTEGER NOT NULL DEFAULT 0,
  edges_removed INTEGER NOT NULL DEFAULT 0,
  edges_changed INTEGER NOT NULL DEFAULT 0,
  status_changes INTEGER NOT NULL DEFAULT 0,
  foundational_changes INTEGER NOT NULL DEFAULT 0,
  mass_change_halt INTEGER NOT NULL DEFAULT 0 CHECK(mass_change_halt IN (0,1)),
  details_json TEXT NOT NULL DEFAULT '{}',
  created_at TEXT NOT NULL
);

CREATE TABLE snapshots (
  snapshot_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL REFERENCES research_runs(run_id),
  phase TEXT NOT NULL CHECK(phase IN ('pre_run','post_staging','post_run','release')),
  path TEXT NOT NULL,
  sha256 TEXT NOT NULL CHECK(length(sha256)=64),
  size_bytes INTEGER NOT NULL CHECK(size_bytes>=0),
  created_at TEXT NOT NULL,
  UNIQUE(run_id,phase,path)
);

CREATE TABLE release_records (
  release_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL REFERENCES research_runs(run_id),
  version TEXT NOT NULL UNIQUE,
  database_sha256 TEXT NOT NULL CHECK(length(database_sha256)=64),
  archive_path TEXT NOT NULL,
  archive_sha256 TEXT NOT NULL CHECK(length(archive_sha256)=64),
  manifest_sha256 TEXT NOT NULL CHECK(length(manifest_sha256)=64),
  restore_verified INTEGER NOT NULL CHECK(restore_verified IN (0,1)),
  created_at TEXT NOT NULL
);

CREATE TABLE release_files (
  release_id TEXT NOT NULL REFERENCES release_records(release_id),
  path TEXT NOT NULL,
  sha256 TEXT NOT NULL CHECK(length(sha256)=64),
  size_bytes INTEGER NOT NULL CHECK(size_bytes>=0),
  PRIMARY KEY(release_id,path)
) WITHOUT ROWID;

CREATE VIEW current_source_versions AS
SELECT sv.* FROM source_versions sv
WHERE NOT EXISTS (SELECT 1 FROM source_versions newer WHERE newer.supersedes_source_version_id=sv.source_version_id);

CREATE VIEW current_entity_versions AS
SELECT ev.* FROM entity_versions ev
WHERE NOT EXISTS (SELECT 1 FROM entity_versions newer WHERE newer.supersedes_entity_version_id=ev.entity_version_id);

CREATE VIEW current_evidence_spans AS
SELECT ev.* FROM evidence_spans ev
WHERE NOT EXISTS (SELECT 1 FROM evidence_spans newer WHERE newer.supersedes_evidence_span_id=ev.evidence_span_id);

CREATE VIEW current_claim_reviews AS
SELECT cr.* FROM claim_reviews cr
WHERE NOT EXISTS (SELECT 1 FROM claim_reviews newer WHERE newer.supersedes_review_id=cr.review_id);

CREATE VIEW current_claim_versions AS
SELECT cv.* FROM claim_versions cv
WHERE NOT EXISTS (SELECT 1 FROM claim_versions newer WHERE newer.supersedes_claim_version_id=cv.claim_version_id);

CREATE VIEW full_research_graph AS SELECT * FROM current_claim_versions;
CREATE VIEW provisional_graph AS SELECT * FROM current_claim_versions WHERE state NOT IN ('rejected','retracted','duplicate');

CREATE VIEW canonical_graph AS
SELECT cv.* FROM current_claim_versions cv
WHERE cv.state='accepted'
  AND cv.review_tier>=2
  AND cv.context_json<>'{}'
  AND EXISTS (
    SELECT 1 FROM claim_evidence ce
    JOIN evidence_spans es ON es.evidence_span_id=ce.evidence_span_id
    JOIN source_files sf ON sf.sha256=es.source_file_sha256
    WHERE ce.claim_version_id=cv.claim_version_id
  )
  AND EXISTS (
    SELECT 1 FROM current_claim_reviews cr
    WHERE cr.claim_version_id=cv.claim_version_id AND cr.review_pass=2
      AND cr.independent=1 AND cr.result='agree'
  )
  AND NOT EXISTS (
    SELECT 1 FROM claim_evidence ce
    JOIN evidence_spans es ON es.evidence_span_id=ce.evidence_span_id
    LEFT JOIN source_authenticity_checks sac ON sac.source_version_id=es.source_version_id
      AND sac.resolution_status='pass'
    WHERE ce.claim_version_id=cv.claim_version_id AND sac.check_id IS NULL
  );

CREATE VIEW contradiction_graph AS
SELECT cv.* FROM contradiction_versions cv
WHERE NOT EXISTS (SELECT 1 FROM contradiction_versions newer WHERE newer.supersedes_contradiction_version_id=cv.contradiction_version_id);

-- Append-only protection.
CREATE TRIGGER no_update_source_versions BEFORE UPDATE ON source_versions BEGIN SELECT RAISE(ABORT,'source_versions are append-only'); END;
CREATE TRIGGER no_delete_source_versions BEFORE DELETE ON source_versions BEGIN SELECT RAISE(ABORT,'source_versions are append-only'); END;
CREATE TRIGGER no_update_source_files BEFORE UPDATE ON source_files BEGIN SELECT RAISE(ABORT,'source_files are immutable'); END;
CREATE TRIGGER no_delete_source_files BEFORE DELETE ON source_files BEGIN SELECT RAISE(ABORT,'source_files are immutable'); END;
CREATE TRIGGER no_update_entity_versions BEFORE UPDATE ON entity_versions BEGIN SELECT RAISE(ABORT,'entity_versions are append-only'); END;
CREATE TRIGGER no_delete_entity_versions BEFORE DELETE ON entity_versions BEGIN SELECT RAISE(ABORT,'entity_versions are append-only'); END;
CREATE TRIGGER no_update_evidence_spans BEFORE UPDATE ON evidence_spans BEGIN SELECT RAISE(ABORT,'evidence_spans are append-only'); END;
CREATE TRIGGER no_delete_evidence_spans BEFORE DELETE ON evidence_spans BEGIN SELECT RAISE(ABORT,'evidence_spans are append-only'); END;
CREATE TRIGGER no_update_claim_versions BEFORE UPDATE ON claim_versions BEGIN SELECT RAISE(ABORT,'claim_versions are append-only'); END;
CREATE TRIGGER no_delete_claim_versions BEFORE DELETE ON claim_versions BEGIN SELECT RAISE(ABORT,'claim_versions are append-only'); END;
CREATE TRIGGER no_update_claim_evidence BEFORE UPDATE ON claim_evidence BEGIN SELECT RAISE(ABORT,'claim_evidence is append-only'); END;
CREATE TRIGGER no_delete_claim_evidence BEFORE DELETE ON claim_evidence BEGIN SELECT RAISE(ABORT,'claim_evidence is append-only'); END;
CREATE TRIGGER no_update_claim_reviews BEFORE UPDATE ON claim_reviews BEGIN SELECT RAISE(ABORT,'claim_reviews are append-only'); END;
CREATE TRIGGER no_delete_claim_reviews BEFORE DELETE ON claim_reviews BEGIN SELECT RAISE(ABORT,'claim_reviews are append-only'); END;
CREATE TRIGGER no_update_contradiction_versions BEFORE UPDATE ON contradiction_versions BEGIN SELECT RAISE(ABORT,'contradiction_versions are append-only'); END;
CREATE TRIGGER no_delete_contradiction_versions BEFORE DELETE ON contradiction_versions BEGIN SELECT RAISE(ABORT,'contradiction_versions are append-only'); END;
CREATE TRIGGER no_update_question_versions BEFORE UPDATE ON question_versions BEGIN SELECT RAISE(ABORT,'question_versions are append-only'); END;
CREATE TRIGGER no_delete_question_versions BEFORE DELETE ON question_versions BEGIN SELECT RAISE(ABORT,'question_versions are append-only'); END;
CREATE TRIGGER no_update_run_events BEFORE UPDATE ON run_events BEGIN SELECT RAISE(ABORT,'run_events are append-only'); END;
CREATE TRIGGER no_delete_run_events BEFORE DELETE ON run_events BEGIN SELECT RAISE(ABORT,'run_events are append-only'); END;
CREATE TRIGGER no_update_validation_runs BEFORE UPDATE ON validation_runs BEGIN SELECT RAISE(ABORT,'validation_runs are append-only'); END;
CREATE TRIGGER no_delete_validation_runs BEFORE DELETE ON validation_runs BEGIN SELECT RAISE(ABORT,'validation_runs are append-only'); END;
CREATE TRIGGER no_update_validation_findings BEFORE UPDATE ON validation_findings BEGIN SELECT RAISE(ABORT,'validation_findings are append-only'); END;
CREATE TRIGGER no_delete_validation_findings BEFORE DELETE ON validation_findings BEGIN SELECT RAISE(ABORT,'validation_findings are append-only'); END;
CREATE TRIGGER no_update_graph_diffs BEFORE UPDATE ON graph_diffs BEGIN SELECT RAISE(ABORT,'graph_diffs are append-only'); END;
CREATE TRIGGER no_delete_graph_diffs BEFORE DELETE ON graph_diffs BEGIN SELECT RAISE(ABORT,'graph_diffs are append-only'); END;
CREATE TRIGGER no_update_snapshots BEFORE UPDATE ON snapshots BEGIN SELECT RAISE(ABORT,'snapshots are append-only'); END;
CREATE TRIGGER no_delete_snapshots BEFORE DELETE ON snapshots BEGIN SELECT RAISE(ABORT,'snapshots are append-only'); END;
CREATE TRIGGER no_update_release_records BEFORE UPDATE ON release_records BEGIN SELECT RAISE(ABORT,'release_records are append-only'); END;
CREATE TRIGGER no_delete_release_records BEFORE DELETE ON release_records BEGIN SELECT RAISE(ABORT,'release_records are append-only'); END;
CREATE TRIGGER no_update_release_files BEFORE UPDATE ON release_files BEGIN SELECT RAISE(ABORT,'release_files are append-only'); END;
CREATE TRIGGER no_delete_release_files BEFORE DELETE ON release_files BEGIN SELECT RAISE(ABORT,'release_files are append-only'); END;
