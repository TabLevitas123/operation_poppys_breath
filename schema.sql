PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;

CREATE TABLE IF NOT EXISTS metadata (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS sources (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    authors_json TEXT NOT NULL DEFAULT '[]',
    publication_year INTEGER,
    journal TEXT,
    doi TEXT,
    pmid TEXT,
    pmcid TEXT,
    url TEXT,
    source_type TEXT NOT NULL,
    publication_status TEXT NOT NULL DEFAULT 'published',
    access_status TEXT NOT NULL DEFAULT 'unknown',
    license TEXT,
    language TEXT DEFAULT 'en',
    retrieval_date TEXT,
    fulltext_sha256 TEXT,
    notes TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_sources_doi
ON sources(doi) WHERE doi IS NOT NULL AND doi <> '';

CREATE UNIQUE INDEX IF NOT EXISTS idx_sources_pmid
ON sources(pmid) WHERE pmid IS NOT NULL AND pmid <> '';

CREATE TABLE IF NOT EXISTS entities (
    id TEXT PRIMARY KEY,
    canonical_name TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    identifiers_json TEXT NOT NULL DEFAULT '{}',
    synonyms_json TEXT NOT NULL DEFAULT '[]',
    description TEXT,
    species TEXT,
    status TEXT NOT NULL DEFAULT 'active',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_entities_type ON entities(entity_type);
CREATE INDEX IF NOT EXISTS idx_entities_name ON entities(canonical_name);

CREATE TABLE IF NOT EXISTS notes (
    id TEXT PRIMARY KEY,
    source_id TEXT,
    note_type TEXT NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    section TEXT,
    page TEXT,
    figure TEXT,
    tags_json TEXT NOT NULL DEFAULT '[]',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY(source_id) REFERENCES sources(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_notes_source ON notes(source_id);
CREATE INDEX IF NOT EXISTS idx_notes_type ON notes(note_type);

CREATE TABLE IF NOT EXISTS claims (
    id TEXT PRIMARY KEY,
    subject_entity_id TEXT NOT NULL,
    predicate TEXT NOT NULL,
    object_entity_id TEXT,
    object_literal TEXT,
    polarity TEXT NOT NULL DEFAULT 'positive',
    causal_strength TEXT NOT NULL DEFAULT 'unresolved',
    evidence_directness TEXT NOT NULL DEFAULT 'unspecified',
    species TEXT,
    sex TEXT,
    age TEXT,
    tissue TEXT,
    brain_region TEXT,
    cell_type TEXT,
    subcellular_location TEXT,
    ligand TEXT,
    dose TEXT,
    route TEXT,
    exposure_state TEXT,
    timepoint TEXT,
    assay TEXT,
    comparator TEXT,
    effect_size TEXT,
    uncertainty TEXT,
    risk_of_bias TEXT,
    replication_status TEXT NOT NULL DEFAULT 'not_assessed',
    curator_confidence REAL CHECK(curator_confidence IS NULL OR
                                  (curator_confidence >= 0 AND curator_confidence <= 1)),
    source_id TEXT NOT NULL,
    source_locator TEXT NOT NULL,
    supporting_text TEXT,
    curator_interpretation TEXT,
    status TEXT NOT NULL DEFAULT 'active',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    CHECK (
        (object_entity_id IS NOT NULL AND object_literal IS NULL)
        OR
        (object_entity_id IS NULL AND object_literal IS NOT NULL)
    ),
    FOREIGN KEY(subject_entity_id) REFERENCES entities(id) ON DELETE RESTRICT,
    FOREIGN KEY(object_entity_id) REFERENCES entities(id) ON DELETE RESTRICT,
    FOREIGN KEY(source_id) REFERENCES sources(id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_claims_subject ON claims(subject_entity_id);
CREATE INDEX IF NOT EXISTS idx_claims_object ON claims(object_entity_id);
CREATE INDEX IF NOT EXISTS idx_claims_predicate ON claims(predicate);
CREATE INDEX IF NOT EXISTS idx_claims_source ON claims(source_id);
CREATE INDEX IF NOT EXISTS idx_claims_region ON claims(brain_region);

CREATE TABLE IF NOT EXISTS contradictions (
    id TEXT PRIMARY KEY,
    claim_a_id TEXT NOT NULL,
    claim_b_id TEXT NOT NULL,
    summary TEXT NOT NULL,
    possible_explanations_json TEXT NOT NULL DEFAULT '[]',
    resolution_status TEXT NOT NULL DEFAULT 'open',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    CHECK(claim_a_id <> claim_b_id),
    FOREIGN KEY(claim_a_id) REFERENCES claims(id) ON DELETE CASCADE,
    FOREIGN KEY(claim_b_id) REFERENCES claims(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS open_questions (
    id TEXT PRIMARY KEY,
    question TEXT NOT NULL,
    rationale TEXT,
    linked_entity_ids_json TEXT NOT NULL DEFAULT '[]',
    priority TEXT NOT NULL DEFAULT 'medium',
    status TEXT NOT NULL DEFAULT 'open',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS documents (
    id TEXT PRIMARY KEY,
    document_type TEXT NOT NULL,
    foreign_id TEXT NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    tags_json TEXT NOT NULL DEFAULT '[]',
    content_sha256 TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    UNIQUE(document_type, foreign_id)
);

CREATE TABLE IF NOT EXISTS embedding_models (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    provider TEXT NOT NULL,
    dimensions INTEGER NOT NULL CHECK(dimensions > 0),
    distance_metric TEXT NOT NULL DEFAULT 'cosine',
    metadata_json TEXT NOT NULL DEFAULT '{}',
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS embeddings (
    document_id TEXT NOT NULL,
    model_id TEXT NOT NULL,
    vector_blob BLOB NOT NULL,
    dimensions INTEGER NOT NULL CHECK(dimensions > 0),
    normalized INTEGER NOT NULL DEFAULT 1 CHECK(normalized IN (0,1)),
    content_sha256 TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    PRIMARY KEY(document_id, model_id),
    FOREIGN KEY(document_id) REFERENCES documents(id) ON DELETE CASCADE,
    FOREIGN KEY(model_id) REFERENCES embedding_models(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS embedding_queue (
    document_id TEXT PRIMARY KEY,
    status TEXT NOT NULL DEFAULT 'pending',
    attempts INTEGER NOT NULL DEFAULT 0,
    last_error TEXT,
    queued_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY(document_id) REFERENCES documents(id) ON DELETE CASCADE
);

CREATE VIRTUAL TABLE IF NOT EXISTS documents_fts USING fts5(
    document_id UNINDEXED,
    title,
    content,
    tags,
    tokenize='unicode61 remove_diacritics 2'
);
