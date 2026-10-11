BEGIN TRANSACTION;
CREATE TABLE allowed_semantic_patterns (
  subject_type TEXT NOT NULL,
  predicate TEXT NOT NULL,
  object_type TEXT NOT NULL,
  PRIMARY KEY(subject_type,predicate,object_type)
) WITHOUT ROWID;
INSERT INTO "allowed_semantic_patterns" VALUES('brain_region','CONTAINS','cell_population');
INSERT INTO "allowed_semantic_patterns" VALUES('gene','HAS_APPROVED_GENE_IDENTITY','literal');
INSERT INTO "allowed_semantic_patterns" VALUES('gene','HAS_REVIEWED_UNIPROT_ENTRY','protein');
INSERT INTO "allowed_semantic_patterns" VALUES('gene','MAPS_TO_IUPHAR_RECEPTOR_TARGET','receptor_target');
INSERT INTO "allowed_semantic_patterns" VALUES('ligand','AGONIZES','receptor_target');
INSERT INTO "allowed_semantic_patterns" VALUES('neuron','PROJECTS_TO','brain_region');
INSERT INTO "allowed_semantic_patterns" VALUES('receptor_target','COUPLES_TO','g_protein');
CREATE TABLE claim_evidence (
  claim_version_id TEXT NOT NULL REFERENCES claim_versions(claim_version_id),
  evidence_span_id TEXT NOT NULL REFERENCES evidence_spans(evidence_span_id),
  evidence_weight TEXT NOT NULL DEFAULT 'supporting',
  PRIMARY KEY(claim_version_id, evidence_span_id)
) WITHOUT ROWID;
INSERT INTO "claim_evidence" VALUES('AST-OPRD1-GENE_IDENTITY-v1','EV-OPRD1-NCBI_GENE','supporting');
INSERT INTO "claim_evidence" VALUES('AST-OPRD1-GENE_TO_IUPHAR-v1','EV-OPRD1-IUPHAR','supporting');
INSERT INTO "claim_evidence" VALUES('AST-OPRD1-GENE_TO_PROTEIN-v1','EV-OPRD1-UNIPROT','supporting');
INSERT INTO "claim_evidence" VALUES('AST-OPRK1-GENE_IDENTITY-v1','EV-OPRK1-NCBI_GENE','supporting');
INSERT INTO "claim_evidence" VALUES('AST-OPRK1-GENE_TO_IUPHAR-v1','EV-OPRK1-IUPHAR','supporting');
INSERT INTO "claim_evidence" VALUES('AST-OPRK1-GENE_TO_PROTEIN-v1','EV-OPRK1-UNIPROT','supporting');
INSERT INTO "claim_evidence" VALUES('AST-OPRL1-GENE_IDENTITY-v1','EV-OPRL1-NCBI_GENE','supporting');
INSERT INTO "claim_evidence" VALUES('AST-OPRL1-GENE_TO_IUPHAR-v1','EV-OPRL1-IUPHAR','supporting');
INSERT INTO "claim_evidence" VALUES('AST-OPRL1-GENE_TO_PROTEIN-v1','EV-OPRL1-UNIPROT','supporting');
INSERT INTO "claim_evidence" VALUES('AST-OPRM1-GENE_IDENTITY-v1','EV-OPRM1-NCBI_GENE','supporting');
INSERT INTO "claim_evidence" VALUES('AST-OPRM1-GENE_TO_IUPHAR-v1','EV-OPRM1-IUPHAR','supporting');
INSERT INTO "claim_evidence" VALUES('AST-OPRM1-GENE_TO_PROTEIN-v1','EV-OPRM1-UNIPROT','supporting');
CREATE TABLE claim_reviews (
  review_id TEXT PRIMARY KEY,
  claim_version_id TEXT NOT NULL REFERENCES claim_versions(claim_version_id),
  review_pass INTEGER NOT NULL CHECK(review_pass IN (1,2)),
  reviewer_class TEXT NOT NULL,
  independent INTEGER NOT NULL CHECK(independent IN (0,1)),
  result TEXT NOT NULL CHECK(result IN ('agree','disagree','needs_adjudication','not_reviewed')),
  checks_json TEXT NOT NULL DEFAULT '{}',
  notes TEXT,
  reviewed_in_run TEXT NOT NULL REFERENCES research_runs(run_id),
  reviewed_at TEXT NOT NULL
, version_no INTEGER NOT NULL DEFAULT 1 CHECK(version_no > 0), supersedes_review_id TEXT REFERENCES claim_reviews(review_id), recorded_in_run TEXT REFERENCES research_runs(run_id), change_reason TEXT);
INSERT INTO "claim_reviews" VALUES('VER-AST-OPRM1-GENE_IDENTITY','AST-OPRM1-GENE_IDENTITY-v1',2,'same_model_second_pass',0,'agree','{"scope":"identity fields"}','Not a separate human or model instance; retained at Tier 1.','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T10:50:28-04:00',1,NULL,NULL,NULL);
INSERT INTO "claim_reviews" VALUES('VER-AST-OPRM1-GENE_TO_PROTEIN','AST-OPRM1-GENE_TO_PROTEIN-v1',2,'same_model_second_pass',0,'agree','{"scope":"identity fields"}','Not a separate human or model instance; retained at Tier 1.','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T10:50:28-04:00',1,NULL,NULL,NULL);
INSERT INTO "claim_reviews" VALUES('VER-AST-OPRM1-GENE_TO_IUPHAR','AST-OPRM1-GENE_TO_IUPHAR-v1',2,'same_model_second_pass',0,'agree','{"scope":"identity fields"}','Not a separate human or model instance; retained at Tier 1.','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T10:50:28-04:00',1,NULL,NULL,NULL);
INSERT INTO "claim_reviews" VALUES('VER-AST-OPRD1-GENE_IDENTITY','AST-OPRD1-GENE_IDENTITY-v1',2,'same_model_second_pass',0,'agree','{"scope":"identity fields"}','Not a separate human or model instance; retained at Tier 1.','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T10:50:28-04:00',1,NULL,NULL,NULL);
INSERT INTO "claim_reviews" VALUES('VER-AST-OPRD1-GENE_TO_PROTEIN','AST-OPRD1-GENE_TO_PROTEIN-v1',2,'same_model_second_pass',0,'agree','{"scope":"identity fields"}','Not a separate human or model instance; retained at Tier 1.','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T10:50:28-04:00',1,NULL,NULL,NULL);
INSERT INTO "claim_reviews" VALUES('VER-AST-OPRD1-GENE_TO_IUPHAR','AST-OPRD1-GENE_TO_IUPHAR-v1',2,'same_model_second_pass',0,'agree','{"scope":"identity fields"}','Not a separate human or model instance; retained at Tier 1.','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T10:50:28-04:00',1,NULL,NULL,NULL);
INSERT INTO "claim_reviews" VALUES('VER-AST-OPRK1-GENE_IDENTITY','AST-OPRK1-GENE_IDENTITY-v1',2,'same_model_second_pass',0,'agree','{"scope":"identity fields"}','Not a separate human or model instance; retained at Tier 1.','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T10:50:28-04:00',1,NULL,NULL,NULL);
INSERT INTO "claim_reviews" VALUES('VER-AST-OPRK1-GENE_TO_PROTEIN','AST-OPRK1-GENE_TO_PROTEIN-v1',2,'same_model_second_pass',0,'agree','{"scope":"identity fields"}','Not a separate human or model instance; retained at Tier 1.','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T10:50:28-04:00',1,NULL,NULL,NULL);
INSERT INTO "claim_reviews" VALUES('VER-AST-OPRK1-GENE_TO_IUPHAR','AST-OPRK1-GENE_TO_IUPHAR-v1',2,'same_model_second_pass',0,'agree','{"scope":"identity fields"}','Not a separate human or model instance; retained at Tier 1.','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T10:50:28-04:00',1,NULL,NULL,NULL);
INSERT INTO "claim_reviews" VALUES('VER-AST-OPRL1-GENE_IDENTITY','AST-OPRL1-GENE_IDENTITY-v1',2,'same_model_second_pass',0,'agree','{"scope":"identity fields"}','Not a separate human or model instance; retained at Tier 1.','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T10:50:28-04:00',1,NULL,NULL,NULL);
INSERT INTO "claim_reviews" VALUES('VER-AST-OPRL1-GENE_TO_PROTEIN','AST-OPRL1-GENE_TO_PROTEIN-v1',2,'same_model_second_pass',0,'agree','{"scope":"identity fields"}','Not a separate human or model instance; retained at Tier 1.','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T10:50:28-04:00',1,NULL,NULL,NULL);
INSERT INTO "claim_reviews" VALUES('VER-AST-OPRL1-GENE_TO_IUPHAR','AST-OPRL1-GENE_TO_IUPHAR-v1',2,'same_model_second_pass',0,'agree','{"scope":"identity fields"}','Not a separate human or model instance; retained at Tier 1.','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T10:50:28-04:00',1,NULL,NULL,NULL);
INSERT INTO "claim_reviews" VALUES('VER-AST-OPRM1-GENE_IDENTITY-v2','AST-OPRM1-GENE_IDENTITY-v1',2,'same_model_second_pass',0,'agree','{"scope":"identity fields","scope_checked":["identifier","species","entity_type","polarity","mapping_scope"]}','Not a separate human or model instance; retained at Tier 1.','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T10:50:28-04:00',2,'VER-AST-OPRM1-GENE_IDENTITY','ocsa-20261011-module1a-metadata-reconciliation-001','Historical review scope transcribed from archived staging');
INSERT INTO "claim_reviews" VALUES('VER-AST-OPRM1-GENE_TO_PROTEIN-v2','AST-OPRM1-GENE_TO_PROTEIN-v1',2,'same_model_second_pass',0,'agree','{"scope":"identity fields","scope_checked":["identifier","species","entity_type","polarity","mapping_scope"]}','Not a separate human or model instance; retained at Tier 1.','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T10:50:28-04:00',2,'VER-AST-OPRM1-GENE_TO_PROTEIN','ocsa-20261011-module1a-metadata-reconciliation-001','Historical review scope transcribed from archived staging');
INSERT INTO "claim_reviews" VALUES('VER-AST-OPRM1-GENE_TO_IUPHAR-v2','AST-OPRM1-GENE_TO_IUPHAR-v1',2,'same_model_second_pass',0,'agree','{"scope":"identity fields","scope_checked":["identifier","species","entity_type","polarity","mapping_scope"]}','Not a separate human or model instance; retained at Tier 1.','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T10:50:28-04:00',2,'VER-AST-OPRM1-GENE_TO_IUPHAR','ocsa-20261011-module1a-metadata-reconciliation-001','Historical review scope transcribed from archived staging');
INSERT INTO "claim_reviews" VALUES('VER-AST-OPRD1-GENE_IDENTITY-v2','AST-OPRD1-GENE_IDENTITY-v1',2,'same_model_second_pass',0,'agree','{"scope":"identity fields","scope_checked":["identifier","species","entity_type","polarity","mapping_scope"]}','Not a separate human or model instance; retained at Tier 1.','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T10:50:28-04:00',2,'VER-AST-OPRD1-GENE_IDENTITY','ocsa-20261011-module1a-metadata-reconciliation-001','Historical review scope transcribed from archived staging');
INSERT INTO "claim_reviews" VALUES('VER-AST-OPRD1-GENE_TO_PROTEIN-v2','AST-OPRD1-GENE_TO_PROTEIN-v1',2,'same_model_second_pass',0,'agree','{"scope":"identity fields","scope_checked":["identifier","species","entity_type","polarity","mapping_scope"]}','Not a separate human or model instance; retained at Tier 1.','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T10:50:28-04:00',2,'VER-AST-OPRD1-GENE_TO_PROTEIN','ocsa-20261011-module1a-metadata-reconciliation-001','Historical review scope transcribed from archived staging');
INSERT INTO "claim_reviews" VALUES('VER-AST-OPRD1-GENE_TO_IUPHAR-v2','AST-OPRD1-GENE_TO_IUPHAR-v1',2,'same_model_second_pass',0,'agree','{"scope":"identity fields","scope_checked":["identifier","species","entity_type","polarity","mapping_scope"]}','Not a separate human or model instance; retained at Tier 1.','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T10:50:28-04:00',2,'VER-AST-OPRD1-GENE_TO_IUPHAR','ocsa-20261011-module1a-metadata-reconciliation-001','Historical review scope transcribed from archived staging');
INSERT INTO "claim_reviews" VALUES('VER-AST-OPRK1-GENE_IDENTITY-v2','AST-OPRK1-GENE_IDENTITY-v1',2,'same_model_second_pass',0,'agree','{"scope":"identity fields","scope_checked":["identifier","species","entity_type","polarity","mapping_scope"]}','Not a separate human or model instance; retained at Tier 1.','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T10:50:28-04:00',2,'VER-AST-OPRK1-GENE_IDENTITY','ocsa-20261011-module1a-metadata-reconciliation-001','Historical review scope transcribed from archived staging');
INSERT INTO "claim_reviews" VALUES('VER-AST-OPRK1-GENE_TO_PROTEIN-v2','AST-OPRK1-GENE_TO_PROTEIN-v1',2,'same_model_second_pass',0,'agree','{"scope":"identity fields","scope_checked":["identifier","species","entity_type","polarity","mapping_scope"]}','Not a separate human or model instance; retained at Tier 1.','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T10:50:28-04:00',2,'VER-AST-OPRK1-GENE_TO_PROTEIN','ocsa-20261011-module1a-metadata-reconciliation-001','Historical review scope transcribed from archived staging');
INSERT INTO "claim_reviews" VALUES('VER-AST-OPRK1-GENE_TO_IUPHAR-v2','AST-OPRK1-GENE_TO_IUPHAR-v1',2,'same_model_second_pass',0,'agree','{"scope":"identity fields","scope_checked":["identifier","species","entity_type","polarity","mapping_scope"]}','Not a separate human or model instance; retained at Tier 1.','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T10:50:28-04:00',2,'VER-AST-OPRK1-GENE_TO_IUPHAR','ocsa-20261011-module1a-metadata-reconciliation-001','Historical review scope transcribed from archived staging');
INSERT INTO "claim_reviews" VALUES('VER-AST-OPRL1-GENE_IDENTITY-v2','AST-OPRL1-GENE_IDENTITY-v1',2,'same_model_second_pass',0,'agree','{"scope":"identity fields","scope_checked":["identifier","species","entity_type","polarity","mapping_scope"]}','Not a separate human or model instance; retained at Tier 1.','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T10:50:28-04:00',2,'VER-AST-OPRL1-GENE_IDENTITY','ocsa-20261011-module1a-metadata-reconciliation-001','Historical review scope transcribed from archived staging');
INSERT INTO "claim_reviews" VALUES('VER-AST-OPRL1-GENE_TO_PROTEIN-v2','AST-OPRL1-GENE_TO_PROTEIN-v1',2,'same_model_second_pass',0,'agree','{"scope":"identity fields","scope_checked":["identifier","species","entity_type","polarity","mapping_scope"]}','Not a separate human or model instance; retained at Tier 1.','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T10:50:28-04:00',2,'VER-AST-OPRL1-GENE_TO_PROTEIN','ocsa-20261011-module1a-metadata-reconciliation-001','Historical review scope transcribed from archived staging');
INSERT INTO "claim_reviews" VALUES('VER-AST-OPRL1-GENE_TO_IUPHAR-v2','AST-OPRL1-GENE_TO_IUPHAR-v1',2,'same_model_second_pass',0,'agree','{"scope":"identity fields","scope_checked":["identifier","species","entity_type","polarity","mapping_scope"]}','Not a separate human or model instance; retained at Tier 1.','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T10:50:28-04:00',2,'VER-AST-OPRL1-GENE_TO_IUPHAR','ocsa-20261011-module1a-metadata-reconciliation-001','Historical review scope transcribed from archived staging');
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
INSERT INTO "claim_versions" VALUES('AST-OPRM1-GENE_IDENTITY-v1','AST-OPRM1-GENE_IDENTITY',1,NULL,'ENT-GENE-OPRM1-v1','HAS_APPROVED_GENE_IDENTITY',NULL,'{"Ensembl":"ENSG00000112038","HGNC":"HGNC:8156","NCBI_Gene":"4988","full_name":"opioid receptor mu 1","symbol":"OPRM1"}','positive','descriptive','{"species":"Homo sapiens"}','{}','proposed',1,'Module 1A proposed identity assertion','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "claim_versions" VALUES('AST-OPRM1-GENE_TO_PROTEIN-v1','AST-OPRM1-GENE_TO_PROTEIN',1,NULL,'ENT-GENE-OPRM1-v1','HAS_REVIEWED_UNIPROT_ENTRY','ENT-PROTEIN-P35372-v1',NULL,'positive','descriptive','{"species":"Homo sapiens"}','{}','proposed',1,'Module 1A proposed identity assertion','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "claim_versions" VALUES('AST-OPRM1-GENE_TO_IUPHAR-v1','AST-OPRM1-GENE_TO_IUPHAR',1,NULL,'ENT-GENE-OPRM1-v1','MAPS_TO_IUPHAR_RECEPTOR_TARGET','ENT-IUPHAR-319-v1',NULL,'positive','descriptive','{"species":"Homo sapiens"}','{}','proposed',1,'Module 1A proposed identity assertion','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "claim_versions" VALUES('AST-OPRD1-GENE_IDENTITY-v1','AST-OPRD1-GENE_IDENTITY',1,NULL,'ENT-GENE-OPRD1-v1','HAS_APPROVED_GENE_IDENTITY',NULL,'{"Ensembl":"ENSG00000116329","HGNC":"HGNC:8153","NCBI_Gene":"4985","full_name":"opioid receptor delta 1","symbol":"OPRD1"}','positive','descriptive','{"species":"Homo sapiens"}','{}','proposed',1,'Module 1A proposed identity assertion','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "claim_versions" VALUES('AST-OPRD1-GENE_TO_PROTEIN-v1','AST-OPRD1-GENE_TO_PROTEIN',1,NULL,'ENT-GENE-OPRD1-v1','HAS_REVIEWED_UNIPROT_ENTRY','ENT-PROTEIN-P41143-v1',NULL,'positive','descriptive','{"species":"Homo sapiens"}','{}','proposed',1,'Module 1A proposed identity assertion','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "claim_versions" VALUES('AST-OPRD1-GENE_TO_IUPHAR-v1','AST-OPRD1-GENE_TO_IUPHAR',1,NULL,'ENT-GENE-OPRD1-v1','MAPS_TO_IUPHAR_RECEPTOR_TARGET','ENT-IUPHAR-317-v1',NULL,'positive','descriptive','{"species":"Homo sapiens"}','{}','proposed',1,'Module 1A proposed identity assertion','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "claim_versions" VALUES('AST-OPRK1-GENE_IDENTITY-v1','AST-OPRK1-GENE_IDENTITY',1,NULL,'ENT-GENE-OPRK1-v1','HAS_APPROVED_GENE_IDENTITY',NULL,'{"Ensembl":"ENSG00000082556","HGNC":"HGNC:8154","NCBI_Gene":"4986","full_name":"opioid receptor kappa 1","symbol":"OPRK1"}','positive','descriptive','{"species":"Homo sapiens"}','{}','proposed',1,'Module 1A proposed identity assertion','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "claim_versions" VALUES('AST-OPRK1-GENE_TO_PROTEIN-v1','AST-OPRK1-GENE_TO_PROTEIN',1,NULL,'ENT-GENE-OPRK1-v1','HAS_REVIEWED_UNIPROT_ENTRY','ENT-PROTEIN-P41145-v1',NULL,'positive','descriptive','{"species":"Homo sapiens"}','{}','proposed',1,'Module 1A proposed identity assertion','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "claim_versions" VALUES('AST-OPRK1-GENE_TO_IUPHAR-v1','AST-OPRK1-GENE_TO_IUPHAR',1,NULL,'ENT-GENE-OPRK1-v1','MAPS_TO_IUPHAR_RECEPTOR_TARGET','ENT-IUPHAR-318-v1',NULL,'positive','descriptive','{"species":"Homo sapiens"}','{}','proposed',1,'Module 1A proposed identity assertion','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "claim_versions" VALUES('AST-OPRL1-GENE_IDENTITY-v1','AST-OPRL1-GENE_IDENTITY',1,NULL,'ENT-GENE-OPRL1-v1','HAS_APPROVED_GENE_IDENTITY',NULL,'{"Ensembl":"ENSG00000125510","HGNC":"HGNC:8155","NCBI_Gene":"4987","full_name":"opioid related nociceptin receptor 1","symbol":"OPRL1"}','positive','descriptive','{"species":"Homo sapiens"}','{}','proposed',1,'Module 1A proposed identity assertion','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "claim_versions" VALUES('AST-OPRL1-GENE_TO_PROTEIN-v1','AST-OPRL1-GENE_TO_PROTEIN',1,NULL,'ENT-GENE-OPRL1-v1','HAS_REVIEWED_UNIPROT_ENTRY','ENT-PROTEIN-P41146-v1',NULL,'positive','descriptive','{"species":"Homo sapiens"}','{}','proposed',1,'Module 1A proposed identity assertion','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "claim_versions" VALUES('AST-OPRL1-GENE_TO_IUPHAR-v1','AST-OPRL1-GENE_TO_IUPHAR',1,NULL,'ENT-GENE-OPRL1-v1','MAPS_TO_IUPHAR_RECEPTOR_TARGET','ENT-IUPHAR-320-v1',NULL,'positive','descriptive','{"species":"Homo sapiens"}','{}','proposed',1,'Module 1A proposed identity assertion','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
CREATE TABLE claims (
  claim_id TEXT PRIMARY KEY,
  created_in_run TEXT NOT NULL REFERENCES research_runs(run_id),
  created_at TEXT NOT NULL
);
INSERT INTO "claims" VALUES('AST-OPRM1-GENE_IDENTITY','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "claims" VALUES('AST-OPRM1-GENE_TO_PROTEIN','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "claims" VALUES('AST-OPRM1-GENE_TO_IUPHAR','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "claims" VALUES('AST-OPRD1-GENE_IDENTITY','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "claims" VALUES('AST-OPRD1-GENE_TO_PROTEIN','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "claims" VALUES('AST-OPRD1-GENE_TO_IUPHAR','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "claims" VALUES('AST-OPRK1-GENE_IDENTITY','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "claims" VALUES('AST-OPRK1-GENE_TO_PROTEIN','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "claims" VALUES('AST-OPRK1-GENE_TO_IUPHAR','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "claims" VALUES('AST-OPRL1-GENE_IDENTITY','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "claims" VALUES('AST-OPRL1-GENE_TO_PROTEIN','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "claims" VALUES('AST-OPRL1-GENE_TO_IUPHAR','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
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
CREATE TABLE contradictions (
  contradiction_id TEXT PRIMARY KEY,
  created_in_run TEXT NOT NULL REFERENCES research_runs(run_id),
  created_at TEXT NOT NULL
);
CREATE TABLE entities (
  entity_id TEXT PRIMARY KEY,
  created_in_run TEXT NOT NULL REFERENCES research_runs(run_id),
  created_at TEXT NOT NULL
);
INSERT INTO "entities" VALUES('ENT-GENE-OPRM1','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "entities" VALUES('ENT-PROTEIN-P35372','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "entities" VALUES('ENT-IUPHAR-319','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "entities" VALUES('ENT-GENE-OPRD1','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "entities" VALUES('ENT-PROTEIN-P41143','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "entities" VALUES('ENT-IUPHAR-317','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "entities" VALUES('ENT-GENE-OPRK1','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "entities" VALUES('ENT-PROTEIN-P41145','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "entities" VALUES('ENT-IUPHAR-318','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "entities" VALUES('ENT-GENE-OPRL1','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "entities" VALUES('ENT-PROTEIN-P41146','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "entities" VALUES('ENT-IUPHAR-320','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
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
  definition TEXT,
  status TEXT NOT NULL DEFAULT 'proposed' CHECK(status IN ('proposed','reviewed','accepted','deprecated','rejected','merged','split')),
  change_reason TEXT NOT NULL,
  created_in_run TEXT NOT NULL REFERENCES research_runs(run_id),
  created_at TEXT NOT NULL, chromosomal_location TEXT, metadata_json TEXT NOT NULL DEFAULT '{}',
  UNIQUE(entity_id, version_no),
  CHECK((version_no=1 AND supersedes_entity_version_id IS NULL) OR version_no>1)
);
INSERT INTO "entity_versions" VALUES('ENT-GENE-OPRM1-v1','ENT-GENE-OPRM1',1,NULL,'gene','OPRM1','Homo sapiens','{"Ensembl":"ENSG00000112038","HGNC":"HGNC:8156","NCBI_Gene":"4988"}','["MOP","MOR","LMOR","MOR1","OPRM","M-OR-1"]','opioid receptor mu 1','proposed','Module 1A identifier seed','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00',NULL,'{}');
INSERT INTO "entity_versions" VALUES('ENT-PROTEIN-P35372-v1','ENT-PROTEIN-P35372',1,NULL,'protein','Mu-type opioid receptor','Homo sapiens','{"UniProtKB":"P35372","UniProt_entry_name":"OPRM_HUMAN"}','[]',NULL,'proposed','Module 1A identifier seed','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00',NULL,'{}');
INSERT INTO "entity_versions" VALUES('ENT-IUPHAR-319-v1','ENT-IUPHAR-319',1,NULL,'receptor_target','μ receptor','Homo sapiens','{"GPCRdb":"oprm_human","IUPHAR_target_id":319}','[]',NULL,'proposed','Module 1A identifier seed','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00',NULL,'{}');
INSERT INTO "entity_versions" VALUES('ENT-GENE-OPRD1-v1','ENT-GENE-OPRD1',1,NULL,'gene','OPRD1','Homo sapiens','{"Ensembl":"ENSG00000116329","HGNC":"HGNC:8153","NCBI_Gene":"4985"}','["DOP","DOR","DOR1","OPRD"]','opioid receptor delta 1','proposed','Module 1A identifier seed','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00',NULL,'{}');
INSERT INTO "entity_versions" VALUES('ENT-PROTEIN-P41143-v1','ENT-PROTEIN-P41143',1,NULL,'protein','Delta-type opioid receptor','Homo sapiens','{"UniProtKB":"P41143","UniProt_entry_name":"OPRD_HUMAN"}','[]',NULL,'proposed','Module 1A identifier seed','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00',NULL,'{}');
INSERT INTO "entity_versions" VALUES('ENT-IUPHAR-317-v1','ENT-IUPHAR-317',1,NULL,'receptor_target','δ receptor','Homo sapiens','{"GPCRdb":"oprd_human","IUPHAR_target_id":317}','[]',NULL,'proposed','Module 1A identifier seed','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00',NULL,'{}');
INSERT INTO "entity_versions" VALUES('ENT-GENE-OPRK1-v1','ENT-GENE-OPRK1',1,NULL,'gene','OPRK1','Homo sapiens','{"Ensembl":"ENSG00000082556","HGNC":"HGNC:8154","NCBI_Gene":"4986"}','["KOP","KOR","KOR1","OPRK","KOR-1","K-OR-1"]','opioid receptor kappa 1','proposed','Module 1A identifier seed','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00',NULL,'{}');
INSERT INTO "entity_versions" VALUES('ENT-PROTEIN-P41145-v1','ENT-PROTEIN-P41145',1,NULL,'protein','Kappa-type opioid receptor','Homo sapiens','{"UniProtKB":"P41145","UniProt_entry_name":"OPRK_HUMAN"}','[]',NULL,'proposed','Module 1A identifier seed','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00',NULL,'{}');
INSERT INTO "entity_versions" VALUES('ENT-IUPHAR-318-v1','ENT-IUPHAR-318',1,NULL,'receptor_target','κ receptor','Homo sapiens','{"GPCRdb":"oprk_human","IUPHAR_target_id":318}','[]',NULL,'proposed','Module 1A identifier seed','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00',NULL,'{}');
INSERT INTO "entity_versions" VALUES('ENT-GENE-OPRL1-v1','ENT-GENE-OPRL1',1,NULL,'gene','OPRL1','Homo sapiens','{"Ensembl":"ENSG00000125510","HGNC":"HGNC:8155","NCBI_Gene":"4987"}','["NOP","OOR","KOR3","NOPr","OPRL","ORL1","KOR-3","NOCIR","PNOCR"]','opioid related nociceptin receptor 1','proposed','Module 1A identifier seed','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00',NULL,'{}');
INSERT INTO "entity_versions" VALUES('ENT-PROTEIN-P41146-v1','ENT-PROTEIN-P41146',1,NULL,'protein','Nociceptin receptor','Homo sapiens','{"UniProtKB":"P41146","UniProt_entry_name":"OPRX_HUMAN"}','[]',NULL,'proposed','Module 1A identifier seed','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00',NULL,'{}');
INSERT INTO "entity_versions" VALUES('ENT-IUPHAR-320-v1','ENT-IUPHAR-320',1,NULL,'receptor_target','NOP receptor','Homo sapiens','{"GPCRdb":"oprx_human","IUPHAR_target_id":320}','[]',NULL,'proposed','Module 1A identifier seed','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00',NULL,'{}');
INSERT INTO "entity_versions" VALUES('ENT-IUPHAR-319-v2','ENT-IUPHAR-319',2,'ENT-IUPHAR-319-v1','receptor_target','μ receptor','Homo sapiens','{"GPCRdb":"oprm_human","IUPHAR_target_id":319}','["Mu receptor","MOP","OP3","MOPr","opioid receptor, mu 1","opioid receptor"]',NULL,'proposed','Archived staging fields; biological identity not independently rechecked','ocsa-20261011-module1a-metadata-reconciliation-001','2026-10-11T16:55:41+00:00','6q25.2','{"family":"Opioid receptors","transmembrane_helices":7}');
INSERT INTO "entity_versions" VALUES('ENT-IUPHAR-317-v2','ENT-IUPHAR-317',2,'ENT-IUPHAR-317-v1','receptor_target','δ receptor','Homo sapiens','{"GPCRdb":"oprd_human","IUPHAR_target_id":317}','["DOP","DOR","OP1","Delta receptor","DOR-1","DOPr","opioid receptor"]',NULL,'proposed','Archived staging fields; biological identity not independently rechecked','ocsa-20261011-module1a-metadata-reconciliation-001','2026-10-11T16:55:41+00:00','1p35.3','{"family":"Opioid receptors","transmembrane_helices":7}');
INSERT INTO "entity_versions" VALUES('ENT-IUPHAR-318-v2','ENT-IUPHAR-318',2,'ENT-IUPHAR-318-v1','receptor_target','κ receptor','Homo sapiens','{"GPCRdb":"oprk_human","IUPHAR_target_id":318}','["KOR-1","Kappa receptor","OP2","KOP","KOPr"]',NULL,'proposed','Archived staging fields; biological identity not independently rechecked','ocsa-20261011-module1a-metadata-reconciliation-001','2026-10-11T16:55:41+00:00','8q11.23','{"family":"Opioid receptors","transmembrane_helices":7}');
INSERT INTO "entity_versions" VALUES('ENT-IUPHAR-320-v2','ENT-IUPHAR-320',2,'ENT-IUPHAR-320-v1','receptor_target','NOP receptor','Homo sapiens','{"GPCRdb":"oprx_human","IUPHAR_target_id":320}','["N/OFQ receptor","OP4","KOR-3","NOCIR","kappa3-related opioid receptor","MOR-C","nociceptin receptor ORL1","XOR1","NOP-r","nociceptin/orphanin FQ receptor","NOPr"]',NULL,'proposed','Archived staging fields; biological identity not independently rechecked','ocsa-20261011-module1a-metadata-reconciliation-001','2026-10-11T16:55:41+00:00','20q13.33','{"family":"Opioid receptors","transmembrane_helices":7}');
CREATE TABLE evidence_spans (
  evidence_span_id TEXT PRIMARY KEY,
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
, version_no INTEGER NOT NULL DEFAULT 1 CHECK(version_no > 0), supersedes_evidence_span_id TEXT REFERENCES evidence_spans(evidence_span_id), change_reason TEXT);
INSERT INTO "evidence_spans" VALUES('EV-OPRM1-NCBI_GENE','SRC-OPRM1-NCBI_GENE-v1',NULL,NULL,'Summary / official identity fields',NULL,NULL,NULL,NULL,NULL,NULL,'Official Symbol OPRM1; Official Full Name opioid receptor mu 1; Gene ID 4988; HGNC:8156; ENSG00000112038.','057a5acca74973376669e9ab8386484fdf46a9f889228b11874b76d6838313f3','authoritative_database_field','manual_structured_web_extraction',NULL,NULL,NULL,'{"species":"Homo sapiens"}','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00',1,NULL,NULL);
INSERT INTO "evidence_spans" VALUES('EV-OPRM1-UNIPROT','SRC-OPRM1-UNIPROT-v1',NULL,NULL,'Entry header / protein identity fields',NULL,NULL,NULL,NULL,NULL,NULL,'P35372 · OPRM_HUMAN; Mu-type opioid receptor; Gene OPRM1; reviewed; 400 amino acids.','915764a5c387323c3250ba73eac41a7f25283070dac96867e905630ee82655f3','authoritative_database_field','manual_structured_web_extraction',NULL,NULL,NULL,'{"species":"Homo sapiens"}','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00',1,NULL,NULL);
INSERT INTO "evidence_spans" VALUES('EV-OPRM1-IUPHAR','SRC-OPRM1-IUPHAR-v1',NULL,NULL,'Target header and Gene and Protein Information table',NULL,NULL,NULL,NULL,NULL,NULL,'Target id 319; Nomenclature μ receptor; Human OPRM1; 7 TM; 400 AA; GPCRdb oprm_human.','6aeca9d126bb34fe96495dbe4b76b4a2d760cc342a698c8181e04ea43a2490b5','authoritative_database_field','manual_structured_web_extraction',NULL,NULL,NULL,'{"species":"Homo sapiens"}','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00',1,NULL,NULL);
INSERT INTO "evidence_spans" VALUES('EV-OPRD1-NCBI_GENE','SRC-OPRD1-NCBI_GENE-v1',NULL,NULL,'Summary / official identity fields',NULL,NULL,NULL,NULL,NULL,NULL,'Official Symbol OPRD1; Official Full Name opioid receptor delta 1; Gene ID 4985; HGNC:8153; ENSG00000116329.','ce7ef5694146e24e0970ada63054fa47adf700f3b4b4e58e64f52ec7a1d24bd1','authoritative_database_field','manual_structured_web_extraction',NULL,NULL,NULL,'{"species":"Homo sapiens"}','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00',1,NULL,NULL);
INSERT INTO "evidence_spans" VALUES('EV-OPRD1-UNIPROT','SRC-OPRD1-UNIPROT-v1',NULL,NULL,'Entry header / protein identity fields',NULL,NULL,NULL,NULL,NULL,NULL,'P41143 · OPRD_HUMAN; Delta-type opioid receptor; Gene OPRD1; reviewed; 372 amino acids.','acc3bd11e95543e6d3aa5bd21e2916dfd25b7a273884cd9b723a3149bcada9c5','authoritative_database_field','manual_structured_web_extraction',NULL,NULL,NULL,'{"species":"Homo sapiens"}','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00',1,NULL,NULL);
INSERT INTO "evidence_spans" VALUES('EV-OPRD1-IUPHAR','SRC-OPRD1-IUPHAR-v1',NULL,NULL,'Target header and Gene and Protein Information table',NULL,NULL,NULL,NULL,NULL,NULL,'Target id 317; Nomenclature δ receptor; Human OPRD1; 7 TM; 372 AA; GPCRdb oprd_human.','efa1b1e5690a8afeb760da538ca1aa344103b2f7ee2dafe146b5173047d98e50','authoritative_database_field','manual_structured_web_extraction',NULL,NULL,NULL,'{"species":"Homo sapiens"}','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00',1,NULL,NULL);
INSERT INTO "evidence_spans" VALUES('EV-OPRK1-NCBI_GENE','SRC-OPRK1-NCBI_GENE-v1',NULL,NULL,'Summary / official identity fields',NULL,NULL,NULL,NULL,NULL,NULL,'Official Symbol OPRK1; Official Full Name opioid receptor kappa 1; Gene ID 4986; HGNC:8154; ENSG00000082556.','c70cd6c4d65905cc4ff8917b78aa7db03a9fb859a45254f9722cf9524aa4d555','authoritative_database_field','manual_structured_web_extraction',NULL,NULL,NULL,'{"species":"Homo sapiens"}','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00',1,NULL,NULL);
INSERT INTO "evidence_spans" VALUES('EV-OPRK1-UNIPROT','SRC-OPRK1-UNIPROT-v1',NULL,NULL,'Entry header / protein identity fields',NULL,NULL,NULL,NULL,NULL,NULL,'P41145 · OPRK_HUMAN; Kappa-type opioid receptor; Gene OPRK1; reviewed; 380 amino acids.','8d01550c999d784d2b78a147b362b747b44d3fdb6d7668e417c272069d2861aa','authoritative_database_field','manual_structured_web_extraction',NULL,NULL,NULL,'{"species":"Homo sapiens"}','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00',1,NULL,NULL);
INSERT INTO "evidence_spans" VALUES('EV-OPRK1-IUPHAR','SRC-OPRK1-IUPHAR-v1',NULL,NULL,'Target header and Gene and Protein Information table',NULL,NULL,NULL,NULL,NULL,NULL,'Target id 318; Nomenclature κ receptor; Human OPRK1; 7 TM; 380 AA; GPCRdb oprk_human.','246fe0e0a94005161d047c132f78613855a6c4d33b485d5ced65125ee6051181','authoritative_database_field','manual_structured_web_extraction',NULL,NULL,NULL,'{"species":"Homo sapiens"}','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00',1,NULL,NULL);
INSERT INTO "evidence_spans" VALUES('EV-OPRL1-NCBI_GENE','SRC-OPRL1-NCBI_GENE-v1',NULL,NULL,'Summary / official identity fields',NULL,NULL,NULL,NULL,NULL,NULL,'Official Symbol OPRL1; Official Full Name opioid related nociceptin receptor 1; Gene ID 4987; HGNC:8155; ENSG00000125510.','d5c8cfb6ef3887f22d3a646081d1cd43ef278b455975c771ec4902d45b9ae9a1','authoritative_database_field','manual_structured_web_extraction',NULL,NULL,NULL,'{"species":"Homo sapiens"}','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00',1,NULL,NULL);
INSERT INTO "evidence_spans" VALUES('EV-OPRL1-UNIPROT','SRC-OPRL1-UNIPROT-v1',NULL,NULL,'Entry header / protein identity fields',NULL,NULL,NULL,NULL,NULL,NULL,'P41146 · OPRX_HUMAN; Nociceptin receptor; Gene OPRL1; reviewed; 370 amino acids.','ff4b763e7a2408affb281e80dfab954f4d3188c4ffc3b5e70b2aeadc4ef61e03','authoritative_database_field','manual_structured_web_extraction',NULL,NULL,NULL,'{"species":"Homo sapiens"}','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00',1,NULL,NULL);
INSERT INTO "evidence_spans" VALUES('EV-OPRL1-IUPHAR','SRC-OPRL1-IUPHAR-v1',NULL,NULL,'Target header and Gene and Protein Information table',NULL,NULL,NULL,NULL,NULL,NULL,'Target id 320; Nomenclature NOP receptor; Human OPRL1; 7 TM; 370 AA; GPCRdb oprx_human.','0fec0872d7bd53b68b6b73a4e4b1dac02a52934fba116dac0bcddaa2e61ab69f','authoritative_database_field','manual_structured_web_extraction',NULL,NULL,NULL,'{"species":"Homo sapiens"}','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00',1,NULL,NULL);
INSERT INTO "evidence_spans" VALUES('EV-OPRM1-NCBI_GENE-v2','SRC-OPRM1-NCBI_GENE-v1',NULL,NULL,'Summary / official symbol, official full name, primary source and related identifiers',NULL,NULL,NULL,NULL,NULL,NULL,'Official Symbol OPRM1; Official Full Name opioid receptor mu 1; Gene ID 4988; HGNC:8156; ENSG00000112038.','057a5acca74973376669e9ab8386484fdf46a9f889228b11874b76d6838313f3','authoritative_database_field','manual_structured_web_extraction',NULL,NULL,NULL,'{"species":"Homo sapiens"}','ocsa-20261011-module1a-metadata-reconciliation-001','2026-10-11T16:55:41+00:00',2,'EV-OPRM1-NCBI_GENE','More precise locator from archived staging; excerpt unchanged');
INSERT INTO "evidence_spans" VALUES('EV-OPRM1-UNIPROT-v2','SRC-OPRM1-UNIPROT-v1',NULL,NULL,'Entry header / protein, gene, review status and sequence length',NULL,NULL,NULL,NULL,NULL,NULL,'P35372 · OPRM_HUMAN; Mu-type opioid receptor; Gene OPRM1; reviewed; 400 amino acids.','915764a5c387323c3250ba73eac41a7f25283070dac96867e905630ee82655f3','authoritative_database_field','manual_structured_web_extraction',NULL,NULL,NULL,'{"species":"Homo sapiens"}','ocsa-20261011-module1a-metadata-reconciliation-001','2026-10-11T16:55:41+00:00',2,'EV-OPRM1-UNIPROT','More precise locator from archived staging; excerpt unchanged');
INSERT INTO "evidence_spans" VALUES('EV-OPRD1-NCBI_GENE-v2','SRC-OPRD1-NCBI_GENE-v1',NULL,NULL,'Summary / official symbol, official full name, primary source and related identifiers',NULL,NULL,NULL,NULL,NULL,NULL,'Official Symbol OPRD1; Official Full Name opioid receptor delta 1; Gene ID 4985; HGNC:8153; ENSG00000116329.','ce7ef5694146e24e0970ada63054fa47adf700f3b4b4e58e64f52ec7a1d24bd1','authoritative_database_field','manual_structured_web_extraction',NULL,NULL,NULL,'{"species":"Homo sapiens"}','ocsa-20261011-module1a-metadata-reconciliation-001','2026-10-11T16:55:41+00:00',2,'EV-OPRD1-NCBI_GENE','More precise locator from archived staging; excerpt unchanged');
INSERT INTO "evidence_spans" VALUES('EV-OPRD1-UNIPROT-v2','SRC-OPRD1-UNIPROT-v1',NULL,NULL,'Entry header / protein, gene, review status and sequence length',NULL,NULL,NULL,NULL,NULL,NULL,'P41143 · OPRD_HUMAN; Delta-type opioid receptor; Gene OPRD1; reviewed; 372 amino acids.','acc3bd11e95543e6d3aa5bd21e2916dfd25b7a273884cd9b723a3149bcada9c5','authoritative_database_field','manual_structured_web_extraction',NULL,NULL,NULL,'{"species":"Homo sapiens"}','ocsa-20261011-module1a-metadata-reconciliation-001','2026-10-11T16:55:41+00:00',2,'EV-OPRD1-UNIPROT','More precise locator from archived staging; excerpt unchanged');
INSERT INTO "evidence_spans" VALUES('EV-OPRK1-NCBI_GENE-v2','SRC-OPRK1-NCBI_GENE-v1',NULL,NULL,'Summary / official symbol, official full name, primary source and related identifiers',NULL,NULL,NULL,NULL,NULL,NULL,'Official Symbol OPRK1; Official Full Name opioid receptor kappa 1; Gene ID 4986; HGNC:8154; ENSG00000082556.','c70cd6c4d65905cc4ff8917b78aa7db03a9fb859a45254f9722cf9524aa4d555','authoritative_database_field','manual_structured_web_extraction',NULL,NULL,NULL,'{"species":"Homo sapiens"}','ocsa-20261011-module1a-metadata-reconciliation-001','2026-10-11T16:55:41+00:00',2,'EV-OPRK1-NCBI_GENE','More precise locator from archived staging; excerpt unchanged');
INSERT INTO "evidence_spans" VALUES('EV-OPRK1-UNIPROT-v2','SRC-OPRK1-UNIPROT-v1',NULL,NULL,'Entry header / protein, gene, review status and sequence length',NULL,NULL,NULL,NULL,NULL,NULL,'P41145 · OPRK_HUMAN; Kappa-type opioid receptor; Gene OPRK1; reviewed; 380 amino acids.','8d01550c999d784d2b78a147b362b747b44d3fdb6d7668e417c272069d2861aa','authoritative_database_field','manual_structured_web_extraction',NULL,NULL,NULL,'{"species":"Homo sapiens"}','ocsa-20261011-module1a-metadata-reconciliation-001','2026-10-11T16:55:41+00:00',2,'EV-OPRK1-UNIPROT','More precise locator from archived staging; excerpt unchanged');
INSERT INTO "evidence_spans" VALUES('EV-OPRL1-NCBI_GENE-v2','SRC-OPRL1-NCBI_GENE-v1',NULL,NULL,'Summary / official symbol, official full name, primary source and related identifiers',NULL,NULL,NULL,NULL,NULL,NULL,'Official Symbol OPRL1; Official Full Name opioid related nociceptin receptor 1; Gene ID 4987; HGNC:8155; ENSG00000125510.','d5c8cfb6ef3887f22d3a646081d1cd43ef278b455975c771ec4902d45b9ae9a1','authoritative_database_field','manual_structured_web_extraction',NULL,NULL,NULL,'{"species":"Homo sapiens"}','ocsa-20261011-module1a-metadata-reconciliation-001','2026-10-11T16:55:41+00:00',2,'EV-OPRL1-NCBI_GENE','More precise locator from archived staging; excerpt unchanged');
INSERT INTO "evidence_spans" VALUES('EV-OPRL1-UNIPROT-v2','SRC-OPRL1-UNIPROT-v1',NULL,NULL,'Entry header / protein, gene, review status and sequence length',NULL,NULL,NULL,NULL,NULL,NULL,'P41146 · OPRX_HUMAN; Nociceptin receptor; Gene OPRL1; reviewed; 370 amino acids.','ff4b763e7a2408affb281e80dfab954f4d3188c4ffc3b5e70b2aeadc4ef61e03','authoritative_database_field','manual_structured_web_extraction',NULL,NULL,NULL,'{"species":"Homo sapiens"}','ocsa-20261011-module1a-metadata-reconciliation-001','2026-10-11T16:55:41+00:00',2,'EV-OPRL1-UNIPROT','More precise locator from archived staging; excerpt unchanged');
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
INSERT INTO "graph_diffs" VALUES('diff-06e30b1da75a5b7ca5d13383','ocsa-20260725-module1-receptor-identifiers-001','496c9f0b170a7b8d12e290c263e50488663d894702bf116c357c81f8c2ea8e2d','7870fa83fcfc07c01e2809c8d0504b6fafecf8dba2b067f72aebfb9ace0ff9ea',12,0,0,12,0,0,0,0,0,'{"edge_ids_added":["AST-OPRD1-GENE_IDENTITY-v1","AST-OPRD1-GENE_TO_IUPHAR-v1","AST-OPRD1-GENE_TO_PROTEIN-v1","AST-OPRK1-GENE_IDENTITY-v1","AST-OPRK1-GENE_TO_IUPHAR-v1","AST-OPRK1-GENE_TO_PROTEIN-v1","AST-OPRL1-GENE_IDENTITY-v1","AST-OPRL1-GENE_TO_IUPHAR-v1","AST-OPRL1-GENE_TO_PROTEIN-v1","AST-OPRM1-GENE_IDENTITY-v1","AST-OPRM1-GENE_TO_IUPHAR-v1","AST-OPRM1-GENE_TO_PROTEIN-v1"],"node_ids_added":["ENT-GENE-OPRD1-v1","ENT-GENE-OPRK1-v1","ENT-GENE-OPRL1-v1","ENT-GENE-OPRM1-v1","ENT-IUPHAR-317-v1","ENT-IUPHAR-318-v1","ENT-IUPHAR-319-v1","ENT-IUPHAR-320-v1","ENT-PROTEIN-P35372-v1","ENT-PROTEIN-P41143-v1","ENT-PROTEIN-P41145-v1","ENT-PROTEIN-P41146-v1"]}','2026-07-25T20:54:52+00:00');
INSERT INTO "graph_diffs" VALUES('diff-0e33c8e9843d9fa30f2b93bf','ocsa-20261011-module1a-metadata-reconciliation-001','c220167791352e524586bd1be6fd3a43eebb05aa9a2663c1d016b319f22173a2','7eb3bc33b9639e60aced375edfc4a45c4d3d7f3334e7aa4b4487272272d79f99',0,0,4,0,0,0,0,0,0,'{"edge_ids_added":[],"node_ids_added":[],"node_ids_changed":["ENT-IUPHAR-317","ENT-IUPHAR-318","ENT-IUPHAR-319","ENT-IUPHAR-320"]}','2026-10-11T16:56:05+00:00');
CREATE TABLE metadata (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
) WITHOUT ROWID;
INSERT INTO "metadata" VALUES('canonical_graph_state','accepted');
INSERT INTO "metadata" VALUES('claim_default_state','proposed');
INSERT INTO "metadata" VALUES('created_at','2026-07-25T20:54:23+00:00');
INSERT INTO "metadata" VALUES('dataset_revision','0');
INSERT INTO "metadata" VALUES('last_updated_at','2026-07-25T20:54:23+00:00');
INSERT INTO "metadata" VALUES('project_name','Opioid Causal Systems Atlas');
INSERT INTO "metadata" VALUES('schema_version','0.2.3');
INSERT INTO "metadata" VALUES('validator_version','0.2.3');
CREATE TABLE open_questions (
  question_id TEXT PRIMARY KEY,
  created_in_run TEXT NOT NULL REFERENCES research_runs(run_id),
  created_at TEXT NOT NULL
);
INSERT INTO "open_questions" VALUES('M1-OQ-001','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "open_questions" VALUES('M1-OQ-002','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "open_questions" VALUES('M1-OQ-003','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "open_questions" VALUES('M1-OQ-004','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
CREATE TABLE paper_dossiers (
  dossier_id TEXT PRIMARY KEY,
  source_version_id TEXT NOT NULL REFERENCES source_versions(source_version_id),
  dossier_json TEXT NOT NULL,
  dossier_sha256 TEXT NOT NULL CHECK(length(dossier_sha256)=64),
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
INSERT INTO "question_versions" VALUES('M1-OQ-001-v1','M1-OQ-001',1,NULL,'Which transcript and protein isoform should be the OCSA canonical reference for each receptor, reconciling MANE Select, RefSeq and UniProt canonical choices?',NULL,'high','open','[]','Module 1A open question','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "question_versions" VALUES('M1-OQ-002-v1','M1-OQ-002',1,NULL,'How should OPRM1 six-transmembrane isoforms be represented without conflating them with the canonical seven-transmembrane receptor?',NULL,'high','open','[]','Module 1A open question','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "question_versions" VALUES('M1-OQ-003-v1','M1-OQ-003',1,NULL,'How should reported translational readthrough isoforms for OPRK1 and OPRL1 be versioned and linked to canonical proteins?',NULL,'medium','open','[]','Module 1A open question','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "question_versions" VALUES('M1-OQ-004-v1','M1-OQ-004',1,NULL,'What terminology guard should prevent historical OPRL1 aliases such as KOR-3 from being merged with OPRK1/KOR?',NULL,'critical','open','[]','Module 1A open question','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
CREATE TABLE release_files (
  release_id TEXT NOT NULL REFERENCES release_records(release_id),
  path TEXT NOT NULL,
  sha256 TEXT NOT NULL CHECK(length(sha256)=64),
  size_bytes INTEGER NOT NULL CHECK(size_bytes>=0),
  PRIMARY KEY(release_id,path)
) WITHOUT ROWID;
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','.github/workflows/validate.yml','3a42dd90ec8b457b7dba123f09f9f5687960c43ebc08958b18154f4cbbb4de6e',1049);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','CHANGELOG.md','0272ae574f9d83cfa225708d80298606f0ff960f038969fc23792e7ad0e4ef03',1213);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','LOCAL_FIRST.md','5d35b55e6c6da41ed503b6ebee50ef9ed80d83791876366c02b4b83ba390ddfb',693);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','PERSISTENCE.md','ffbbce5f9aef9baa0e340f75ea532f03167e33131ec175761418bcf072850f62',783);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','README.md','5151da82ecd3e7017d74d1b3991cf507bf5405196b6578dd0df41d3777648e63',1514);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','RUN_PROTOCOL.md','56d89c050e31c7eb5017f71a28cbabdb6e7847c3595222cbcc389b664a0976de',1107);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','atlas.db','744e4da212f4bc85510282b27b7efac889e87b90db8d2be246e11cd0597e41ed',286720);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','changesets/ocsa-20260725-workspace-recovery-hardening-001.json','2e1412c53e2751a110781c3251fa18e09ea6bb11a3da819a6fda17620b2ae249',672);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','config.json','096a1774ef6e8d0bd97c0164755041c095e94fd0f31a60cb0df7e4c0387c0785',515);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','exports/atlas.graphml','165ee7f3eda44eae98924f7dedfe88c53b5ef20a7e036af8c93c0f27e102a7e7',309);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','exports/canonical_graph.csv','b0420058fbed19e635829de3302e098bc3263a0253702685b4d280e9f3adccbb',132);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','exports/canonical_graph.graphml','ae62cfa455fd3e16c9427ac52ddfd2a9ae675efd2bb486f586b7ef02c651159d',1477);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','exports/canonical_graph.jsonl','e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',0);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','exports/claims.jsonl','e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',0);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','exports/contradiction_graph.jsonl','e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',0);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','exports/contradictions.jsonl','e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',0);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','exports/current_entity_versions.jsonl','5cbe5f4e99f770740978fd19122d7b03782be122fd922d8536cd939d01dc3fc9',6382);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','exports/current_source_versions.jsonl','b2264e76be903053ea3ad906b89178bdef35da366e0624d55d4de0d39b855c08',15730);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','exports/documents.jsonl','e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',0);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','exports/entities.jsonl','e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',0);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','exports/evidence_spans.jsonl','ce4558fe58d56d18c7d4193d22dd0d7a927d091583fec25105541f91d666034a',10333);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','exports/full_research_graph.csv','4bd4f289402719b4bb097eacbfdcba73b2bb14ce075299c8c52aa0cb41ec51f8',4410);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','exports/full_research_graph.jsonl','62b7993d4c7f05c614642712d187ded3132591b7f600ab06a1112cfce742119d',8054);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','exports/metadata.jsonl','80d2ada241e4c7e67cd90b70e0cb3d05c8a42263e08bc650a08eb7cf3cf6daca',328);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','exports/notes.jsonl','e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',0);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','exports/open_questions.jsonl','e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',0);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','exports/provisional_graph.csv','4bd4f289402719b4bb097eacbfdcba73b2bb14ce075299c8c52aa0cb41ec51f8',4410);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','exports/provisional_graph.jsonl','62b7993d4c7f05c614642712d187ded3132591b7f600ab06a1112cfce742119d',8054);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','exports/sources.jsonl','e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',0);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','legacy/atlas_v0.1.0.db','f4868ffaad01b2929ff631cb3c284faf4e7f07aa8642a0d724ac565e04de1b95',172032);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','legacy/operation_poppys_breath_v0.1.0-restored.zip','6870b65e7acd05733d9c9b1acf3d8d09920d569493996ca14e16d538ad5332a3',149913);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','legacy/schema_v0.1.0.sql','e192c937a3d68df00f9319fbd5c9691f76d669dbd5279d5cbf390a46133765f9',6309);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','legacy/test_store_v0.1.0.py','a34aad3a7220eaa1b52bc31cec085077b559e9ea28910b879c30b1abb33ad25d',2824);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','reports/database-hashes.txt','8f744c0e212c318dfd1207b1a9243eaec38973da31c986636db485149efb98fe',483);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','reports/final-stats.json','fffb3742eb66f75f86ef1668e99ee7b54538fe93bd15c6ce7bbf41fb5351e27c',995);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','reports/final-validation-report.json','a6b85720747276a0fa8bb28ac6aeffd405c165701a1e5211cd0f9d7aabb99dae',227);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','reports/graph-diff.json','237f3414f9542239ffad59284a5e3dc20720253d22c7ad4a2c9a22b1f53b3672',1330);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','reports/recovery-run-report.md','518124cad7ab437e3e167c290a5a842b2040c56cefeb5ddc66d6618a0a614038',903);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','reports/test-results.json','ad74bc17871f3ae636f196867cd39f9a0f2ab8852a85df429f5e263b7d7e663e',2008);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','reports/test-results.md','80b185d16b5e9e19180b713251be69cd0776fc2617418815fc228646a7ce4678',1922);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','reports/test-results.txt','2b4fb98eae7ac2eab911f68d30943c902c6e595e11624af572161ee815da3da2',1874);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','reports/validation-report.json','81568f4d768e00609072dcfb37aaa8b8e4dd303110080dbd4c983f2bf9685670',227);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','runs/LATEST_STAGING.json','0f556d1fe61a423c2c9092c1ce708ae0977c633b75cc9ada68ae8ca1fa934c43',313);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','runs/ocsa-20260725-module1-receptor-identifiers-001/FILE_MANIFEST.json','02ef3591844aea63ff0f79b1828e70a80b529919380146511a8c50b6867963eb',2633);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','runs/ocsa-20260725-module1-receptor-identifiers-001/changeset.json','6a41211c1058e116e2aca0bd739c3f42fe6c2f99b355ec7029b970e1a3b1eb2c',881);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','runs/ocsa-20260725-module1-receptor-identifiers-001/entities.jsonl','e126cde7adec5ef96e56adac85680d0409837feb64521ae7a638b3422a65804e',3789);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','runs/ocsa-20260725-module1-receptor-identifiers-001/evidence_spans.jsonl','a5d837a55fbef3610afc161066a7f01bb195e22d4bcedf1d0b4d667af62231a5',6433);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','runs/ocsa-20260725-module1-receptor-identifiers-001/graph_diff.json','c3d3c2831426d13b7f98125c3c85a8d6f21d23f9e24cb95152adc98aa32d7165',339);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','runs/ocsa-20260725-module1-receptor-identifiers-001/open_questions.json','324d65a60e363dafa9a6998eeb94a8d46de44fc51345fdaaf8cd8108353004b3',1047);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','runs/ocsa-20260725-module1-receptor-identifiers-001/proposed_assertions.jsonl','48668b013ec0cf79a047a9545b797116cbfb29f333eb84ad25f3db897fdfdefe',7385);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','runs/ocsa-20260725-module1-receptor-identifiers-001/run-report.md','8edc2ec5bd28449bdd36ad82010a916d0383b94c6c9d5cdb6d862c0419e9aaa7',947);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','runs/ocsa-20260725-module1-receptor-identifiers-001/run.json','01e45a3651cf0fadd1b21157ff40547cc1439bca88a072fd1fcf159dd2521691',447);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','runs/ocsa-20260725-module1-receptor-identifiers-001/source_manifest.json','2b7543c2bd3595a6ebc1ecf46f4b804d06683d337cd580116ce7c77da5e5282b',5824);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','runs/ocsa-20260725-module1-receptor-identifiers-001/test_results.json','9f2419e169720a51494d098ae4ea697e8d1ac9de660a8bc6993afeb188869b51',1847);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','runs/ocsa-20260725-module1-receptor-identifiers-001/validation_report.json','0b02bcf460c9e3ebb9925a134ea295e0596ff1c83962c37322ad8fe6f4b51722',504);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','runs/ocsa-20260725-module1-receptor-identifiers-001/verification.jsonl','88cd52e8bdcaf6897a4d182dac9479869b7d31a5336b8dce8484cd7e61db2cea',4500);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','schema.sql','3cc73237c1135309404a3098d756bc839dd76a3e470604ac1d5a1ef832b66b9c',18870);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','scripts/build_release.py','0204bf97517ca318211d8cc8040688df5542280538f7bc09ace89a74d8d72523',2775);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','scripts/verify_release.py','b09d19b14f09ca9008e0780eb6117fb7e72bd41f9c523dc3730ba9c12154ab90',2419);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','snapshots/OCSA_v0.1.0_20260723T193523Z.zip','2f769c28e3f770af7f5f5d182b3a5882c9b29fd0e0e1fa7297c03e4466a985d1',38887);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','snapshots/OCSA_v0.1.0_20260723T193526Z.zip','bb791d69d38817219064650238dfe5d9c84954921d84266ac098dd472cd44a48',75379);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','snapshots/ocsa-20260725-module1-receptor-identifiers-001-post-run.db','ce88b2a05d7513d1bcbb5dcf022f37e9c3c34b35af34300449cb605a6d47f28d',286720);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','snapshots/ocsa-20260725-module1-receptor-identifiers-001-post-staging.db','ba399d4a68272275d04f021a3a97b8b9ef269c5ca9f399d703890fa6814177fc',286720);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','snapshots/ocsa-20260725-workspace-recovery-hardening-001-pre-run.db','496c9f0b170a7b8d12e290c263e50488663d894702bf116c357c81f8c2ea8e2d',266240);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','src/ocsa_store.py','5fbdf6a3566f3ff02dc3a74873a12b9464d248af927006bfe148fbc66cf6c0cc',34169);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','state/WORKSPACE_STATE.json','84a940c238245af784cf32e36e5c988dff3ef242cc1b255d60816ef485785d88',1399);
INSERT INTO "release_files" VALUES('REL-v0.2.2-recovery-base','tests/test_store.py','e8f4967d9bc56a1a964a6e7fc3c6ed28296eae7ab4532c9988579de10b44ac6e',9641);
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
INSERT INTO "release_records" VALUES('REL-v0.2.2-recovery-base','ocsa-20260725-workspace-recovery-hardening-001','v0.2.2-recovery-base','744e4da212f4bc85510282b27b7efac889e87b90db8d2be246e11cd0597e41ed','releases/v0.2.2/OCSA_v0.2.2-recovered-hardened.zip','95d95ca75f310e0c2f53fad706afe5c201e2b0e2954ad5235f0fbaa94d0a6cc6','43c6a1c062690ed63b1fac6f66847260a71b0b2e1107edbc06f594721e028f16',1,'2026-07-25T20:57:36+00:00');
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
INSERT INTO "research_runs" VALUES('ocsa-20260725-workspace-recovery-hardening-001','Module 0 recovery','Restore workspace after reset, rebuild hardened provenance infrastructure, validate locally, and preserve prior v0.1 artifacts.','staging','v0.1.0','f4868ffaad01b2929ff631cb3c284faf4e7f07aa8642a0d724ac565e04de1b95',NULL,'0.2.2','{}','{}','2026-07-25T20:54:24+00:00',NULL,NULL,NULL,'2026-07-25T20:54:24+00:00');
INSERT INTO "research_runs" VALUES('ocsa-20260725-module1-receptor-identifiers-001','Module 1A','Human OPRM1, OPRD1, OPRK1 and OPRL1 nomenclature and stable identifier staging.','staging','workspace-recovery-v0.2.2','0fe0606a6844c59c554ea9c614333aac8ec25127fabbf0773ed9a2cc2cb6f4fa',NULL,'0.2.2','{}','{}','2026-07-25T20:54:24+00:00',NULL,NULL,NULL,'2026-07-25T20:54:24+00:00');
INSERT INTO "research_runs" VALUES('ocsa-20261011-module1a-metadata-reconciliation-001','Module 1A','Archived metadata reconciliation; no source re-authentication','staging',NULL,NULL,NULL,'0.2.2','{}','{}','2026-10-11T16:55:41+00:00',NULL,NULL,NULL,'2026-10-11T16:55:41+00:00');
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
INSERT INTO "run_events" VALUES('evt-bb9f5b58c101195d92077f68','ocsa-20260725-workspace-recovery-hardening-001',1,'run_started','{"module":"Module 0 recovery","scope":"Restore workspace after reset, rebuild hardened provenance infrastructure, validate locally, and preserve prior v0.1 artifacts."}',NULL,'01892bdedee49dadb18c1e0c6eea656853682371913d633b3b682609f57eee82','2026-07-25T20:54:24+00:00');
INSERT INTO "run_events" VALUES('evt-98c1527a3929c549b6d2aee1','ocsa-20260725-workspace-recovery-hardening-001',2,'snapshot_created','{"path":"snapshots/ocsa-20260725-workspace-recovery-hardening-001-pre-run.db","phase":"pre_run","sha256":"496c9f0b170a7b8d12e290c263e50488663d894702bf116c357c81f8c2ea8e2d","size_bytes":266240}','01892bdedee49dadb18c1e0c6eea656853682371913d633b3b682609f57eee82','3887113f4e085b1eeae4fc0febca8176279eeddacaba57cc7110c923ab45c082','2026-07-25T20:54:24+00:00');
INSERT INTO "run_events" VALUES('evt-8e1b9ec145dc0c6d386583b4','ocsa-20260725-module1-receptor-identifiers-001',1,'run_started','{"module":"Module 1A","scope":"Human OPRM1, OPRD1, OPRK1 and OPRL1 nomenclature and stable identifier staging."}',NULL,'b8438dcfce49c46ec73c4317b3dea308a2d8d829857bb553c0a03c01d7924374','2026-07-25T20:54:24+00:00');
INSERT INTO "run_events" VALUES('evt-8c9821d6d41417cdc4ac67bc','ocsa-20260725-module1-receptor-identifiers-001',2,'staging_ingested','{"claims":12,"entities":12,"evidence":12,"questions":4,"sources":12}','b8438dcfce49c46ec73c4317b3dea308a2d8d829857bb553c0a03c01d7924374','8f31e9b9c2638c1bb9ba47f72a8820af9fc2ad6cdb6ccd7660cd87f08d7302c4','2026-07-25T20:54:24+00:00');
INSERT INTO "run_events" VALUES('evt-fb4e382c69d5b95210a8e702','ocsa-20260725-module1-receptor-identifiers-001',3,'snapshot_created','{"path":"snapshots/ocsa-20260725-module1-receptor-identifiers-001-post-staging.db","phase":"post_staging","sha256":"ba399d4a68272275d04f021a3a97b8b9ef269c5ca9f399d703890fa6814177fc","size_bytes":286720}','8f31e9b9c2638c1bb9ba47f72a8820af9fc2ad6cdb6ccd7660cd87f08d7302c4','ba1be6241813a0039d42f4db0093e7dd9484c65194b79606e44caba05a78dba1','2026-07-25T20:54:24+00:00');
INSERT INTO "run_events" VALUES('evt-edc3f16e3d7aa86be48ee51a','ocsa-20260725-module1-receptor-identifiers-001',4,'graph_diff_generated','{"after_database_sha256":"7870fa83fcfc07c01e2809c8d0504b6fafecf8dba2b067f72aebfb9ace0ff9ea","before_database_sha256":"496c9f0b170a7b8d12e290c263e50488663d894702bf116c357c81f8c2ea8e2d","canonical_edges_added":0,"canonical_edges_removed":0,"details":{"edge_ids_added":["AST-OPRD1-GENE_IDENTITY-v1","AST-OPRD1-GENE_TO_IUPHAR-v1","AST-OPRD1-GENE_TO_PROTEIN-v1","AST-OPRK1-GENE_IDENTITY-v1","AST-OPRK1-GENE_TO_IUPHAR-v1","AST-OPRK1-GENE_TO_PROTEIN-v1","AST-OPRL1-GENE_IDENTITY-v1","AST-OPRL1-GENE_TO_IUPHAR-v1","AST-OPRL1-GENE_TO_PROTEIN-v1","AST-OPRM1-GENE_IDENTITY-v1","AST-OPRM1-GENE_TO_IUPHAR-v1","AST-OPRM1-GENE_TO_PROTEIN-v1"],"node_ids_added":["ENT-GENE-OPRD1-v1","ENT-GENE-OPRK1-v1","ENT-GENE-OPRL1-v1","ENT-GENE-OPRM1-v1","ENT-IUPHAR-317-v1","ENT-IUPHAR-318-v1","ENT-IUPHAR-319-v1","ENT-IUPHAR-320-v1","ENT-PROTEIN-P35372-v1","ENT-PROTEIN-P41143-v1","ENT-PROTEIN-P41145-v1","ENT-PROTEIN-P41146-v1"]},"edges_added":12,"edges_changed":0,"edges_removed":0,"foundational_changes":0,"mass_change_halt":false,"nodes_added":12,"nodes_changed":0,"nodes_removed":0,"status_changes":0}','ba1be6241813a0039d42f4db0093e7dd9484c65194b79606e44caba05a78dba1','002b2526a7f6f1fa7ced9c617fb808501e7ec765ec48053734a6439129eca670','2026-07-25T20:54:52+00:00');
INSERT INTO "run_events" VALUES('evt-508cdcb1484f642c8672f7ed','ocsa-20260725-module1-receptor-identifiers-001',5,'validation_completed','{"blocking_count":0,"passed":true,"validation_run_id":"val-a77e2a9e5ffd2cc7723f5c72","warning_count":0}','002b2526a7f6f1fa7ced9c617fb808501e7ec765ec48053734a6439129eca670','980f8747276a829d8d2dfe8efa18d26643008294e47656843bd8c191b8c30975','2026-07-25T20:54:54+00:00');
INSERT INTO "run_events" VALUES('evt-0f091eeb1e1e6c45dad058c4','ocsa-20260725-module1-receptor-identifiers-001',6,'snapshot_created','{"path":"snapshots/ocsa-20260725-module1-receptor-identifiers-001-post-run.db","phase":"post_run","sha256":"ce88b2a05d7513d1bcbb5dcf022f37e9c3c34b35af34300449cb605a6d47f28d","size_bytes":286720}','980f8747276a829d8d2dfe8efa18d26643008294e47656843bd8c191b8c30975','c619e0bc2ee654b1ff37ea9f91fd08c8a9364b8f9157aa1db3f66f5d7bd18f49','2026-07-25T20:54:54+00:00');
INSERT INTO "run_events" VALUES('evt-c84637a53c283403ff99e10a','ocsa-20260725-workspace-recovery-hardening-001',3,'release_verified','{"archive_sha256":"95d95ca75f310e0c2f53fad706afe5c201e2b0e2954ad5235f0fbaa94d0a6cc6","release_id":"REL-v0.2.2-recovery-base","restore_verified":true}','3887113f4e085b1eeae4fc0febca8176279eeddacaba57cc7110c923ab45c082','3769b81dae868d657091509387e5f6724863447170098d5159afa37acea0a377','2026-07-25T20:57:36+00:00');
INSERT INTO "run_events" VALUES('evt-3612d08d5c69ee3befa234f2','ocsa-20260725-workspace-recovery-hardening-001',4,'snapshot_created','{"path":"snapshots/ocsa-20260725-workspace-recovery-hardening-001-release.db","phase":"release","sha256":"47d267df1375345b6381ac211593f5a3d3a74f7471ba2752d8105368c97e6e05","size_bytes":307200}','3769b81dae868d657091509387e5f6724863447170098d5159afa37acea0a377','6f4211c05da08be287b051905a7f9a91f562a97e63bb15cbda5fa6671f164331','2026-07-25T20:57:36+00:00');
INSERT INTO "run_events" VALUES('evt-fbedd1a3679cf6bb1288eb47','ocsa-20261011-module1a-metadata-reconciliation-001',1,'run_started','{"module":"Module 1A","scope":"Archived metadata reconciliation; no source re-authentication"}',NULL,'394f453a4b361006c003cf0ae3fd8412145ee59b41ee2e38c20de478275c56dc','2026-10-11T16:55:41+00:00');
INSERT INTO "run_events" VALUES('evt-f62cb7e33390f1378bbcd9d9','ocsa-20261011-module1a-metadata-reconciliation-001',2,'metadata_reconciled','{"claim_reviews":12,"entity_versions":4,"evidence_spans":8,"manifest_sha256":"b2122eaae29fe7c29ebf3982610e5ecffc4d3cb9325101aa0bc5e70121a8c59b","source_authentication":"not_rechecked","source_versions":12}','394f453a4b361006c003cf0ae3fd8412145ee59b41ee2e38c20de478275c56dc','998356ff93fd376c3772cb4df3ff1fc137823296b6fa380ca1fcb8e02fb638fb','2026-10-11T16:55:41+00:00');
INSERT INTO "run_events" VALUES('evt-9ef98d2135038f6bcacd686d','ocsa-20261011-module1a-metadata-reconciliation-001',3,'graph_diff_generated','{"after_database_sha256":"7eb3bc33b9639e60aced375edfc4a45c4d3d7f3334e7aa4b4487272272d79f99","before_database_sha256":"c220167791352e524586bd1be6fd3a43eebb05aa9a2663c1d016b319f22173a2","canonical_edges_added":0,"canonical_edges_removed":0,"details":{"edge_ids_added":[],"node_ids_added":[],"node_ids_changed":["ENT-IUPHAR-317","ENT-IUPHAR-318","ENT-IUPHAR-319","ENT-IUPHAR-320"]},"edges_added":0,"edges_changed":0,"edges_removed":0,"foundational_changes":0,"mass_change_halt":false,"nodes_added":0,"nodes_changed":4,"nodes_removed":0,"status_changes":0}','998356ff93fd376c3772cb4df3ff1fc137823296b6fa380ca1fcb8e02fb638fb','fe93ef5893b66d3c0e275514be968c9b0b351fe6d05ff308b665cdbf52d39b04','2026-10-11T16:56:05+00:00');
INSERT INTO "run_events" VALUES('evt-d10b91dd71c6f4e0a611b3aa','ocsa-20261011-module1a-metadata-reconciliation-001',4,'snapshot_created','{"path":"snapshots/ocsa-20261011-module1a-metadata-reconciliation-001-post-run.db","phase":"post_run","sha256":"ca65a887758b9d9bc361c7523aefe43467b5c921c2242f85192f002e2bb71048","size_bytes":356352}','fe93ef5893b66d3c0e275514be968c9b0b351fe6d05ff308b665cdbf52d39b04','52dbd9b7fc44e420fc4748c575d0024fd284334019f8a5a5c2a8c498c6ece1c2','2026-10-11T16:56:05+00:00');
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
INSERT INTO "snapshots" VALUES('snap-228bb5425e118c1cd71878c1','ocsa-20260725-workspace-recovery-hardening-001','pre_run','snapshots/ocsa-20260725-workspace-recovery-hardening-001-pre-run.db','496c9f0b170a7b8d12e290c263e50488663d894702bf116c357c81f8c2ea8e2d',266240,'2026-07-25T20:54:24+00:00');
INSERT INTO "snapshots" VALUES('snap-1d7fbe9f185ec3738b2d18ac','ocsa-20260725-module1-receptor-identifiers-001','post_staging','snapshots/ocsa-20260725-module1-receptor-identifiers-001-post-staging.db','ba399d4a68272275d04f021a3a97b8b9ef269c5ca9f399d703890fa6814177fc',286720,'2026-07-25T20:54:24+00:00');
INSERT INTO "snapshots" VALUES('snap-51e5296ff8a9e63b9df33004','ocsa-20260725-module1-receptor-identifiers-001','post_run','snapshots/ocsa-20260725-module1-receptor-identifiers-001-post-run.db','ce88b2a05d7513d1bcbb5dcf022f37e9c3c34b35af34300449cb605a6d47f28d',286720,'2026-07-25T20:54:54+00:00');
INSERT INTO "snapshots" VALUES('snap-56352af5a9c9c1bcaf43ddd2','ocsa-20260725-workspace-recovery-hardening-001','release','snapshots/ocsa-20260725-workspace-recovery-hardening-001-release.db','47d267df1375345b6381ac211593f5a3d3a74f7471ba2752d8105368c97e6e05',307200,'2026-07-25T20:57:36+00:00');
INSERT INTO "snapshots" VALUES('snap-9eaf2e25d01b34f12147dc00','ocsa-20261011-module1a-metadata-reconciliation-001','post_run','snapshots/ocsa-20261011-module1a-metadata-reconciliation-001-post-run.db','ca65a887758b9d9bc361c7523aefe43467b5c921c2242f85192f002e2bb71048',356352,'2026-10-11T16:56:05+00:00');
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
INSERT INTO "source_authenticity_checks" VALUES('sac-53a3fa2c56f77638f5fe0810','SRC-OPRM1-NCBI_GENE-v1',NULL,NULL,NULL,NULL,NULL,NULL,'partial','{"reason":"metadata cross-check only; immutable file absent"}','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_authenticity_checks" VALUES('sac-b02d517b0b7d61dec30532a9','SRC-OPRM1-UNIPROT-v1',NULL,NULL,NULL,NULL,NULL,NULL,'partial','{"reason":"metadata cross-check only; immutable file absent"}','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_authenticity_checks" VALUES('sac-94d758cc327e2eefa8d50f73','SRC-OPRM1-IUPHAR-v1',NULL,NULL,NULL,NULL,NULL,NULL,'partial','{"reason":"metadata cross-check only; immutable file absent"}','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_authenticity_checks" VALUES('sac-3b7cf8bd8c2b9309c61d7acd','SRC-OPRD1-NCBI_GENE-v1',NULL,NULL,NULL,NULL,NULL,NULL,'partial','{"reason":"metadata cross-check only; immutable file absent"}','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_authenticity_checks" VALUES('sac-91601d4777e80b948b0a847b','SRC-OPRD1-UNIPROT-v1',NULL,NULL,NULL,NULL,NULL,NULL,'partial','{"reason":"metadata cross-check only; immutable file absent"}','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_authenticity_checks" VALUES('sac-ea765359e46d11c47d37114e','SRC-OPRD1-IUPHAR-v1',NULL,NULL,NULL,NULL,NULL,NULL,'partial','{"reason":"metadata cross-check only; immutable file absent"}','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_authenticity_checks" VALUES('sac-e30d4a8dc2b367ce6156ec9a','SRC-OPRK1-NCBI_GENE-v1',NULL,NULL,NULL,NULL,NULL,NULL,'partial','{"reason":"metadata cross-check only; immutable file absent"}','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_authenticity_checks" VALUES('sac-f6bc4d20a36ec46c75e7060e','SRC-OPRK1-UNIPROT-v1',NULL,NULL,NULL,NULL,NULL,NULL,'partial','{"reason":"metadata cross-check only; immutable file absent"}','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_authenticity_checks" VALUES('sac-06884a8093e9ab8de382189a','SRC-OPRK1-IUPHAR-v1',NULL,NULL,NULL,NULL,NULL,NULL,'partial','{"reason":"metadata cross-check only; immutable file absent"}','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_authenticity_checks" VALUES('sac-3de67bab752c383faeb4994f','SRC-OPRL1-NCBI_GENE-v1',NULL,NULL,NULL,NULL,NULL,NULL,'partial','{"reason":"metadata cross-check only; immutable file absent"}','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_authenticity_checks" VALUES('sac-4ed68e9187a5770870095082','SRC-OPRL1-UNIPROT-v1',NULL,NULL,NULL,NULL,NULL,NULL,'partial','{"reason":"metadata cross-check only; immutable file absent"}','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_authenticity_checks" VALUES('sac-6ac32813b2b7332660481da8','SRC-OPRL1-IUPHAR-v1',NULL,NULL,NULL,NULL,NULL,NULL,'partial','{"reason":"metadata cross-check only; immutable file absent"}','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
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
CREATE TABLE source_records (
  source_id TEXT PRIMARY KEY,
  created_in_run TEXT NOT NULL REFERENCES research_runs(run_id),
  created_at TEXT NOT NULL
);
INSERT INTO "source_records" VALUES('SRC-OPRM1-NCBI_GENE','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_records" VALUES('SRC-OPRM1-UNIPROT','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_records" VALUES('SRC-OPRM1-IUPHAR','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_records" VALUES('SRC-OPRD1-NCBI_GENE','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_records" VALUES('SRC-OPRD1-UNIPROT','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_records" VALUES('SRC-OPRD1-IUPHAR','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_records" VALUES('SRC-OPRK1-NCBI_GENE','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_records" VALUES('SRC-OPRK1-UNIPROT','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_records" VALUES('SRC-OPRK1-IUPHAR','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_records" VALUES('SRC-OPRL1-NCBI_GENE','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_records" VALUES('SRC-OPRL1-UNIPROT','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_records" VALUES('SRC-OPRL1-IUPHAR','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
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
INSERT INTO "source_versions" VALUES('SRC-OPRM1-NCBI_GENE-v1','SRC-OPRM1-NCBI_GENE',1,NULL,'OPRM1 opioid receptor mu 1 [Homo sapiens]','[]','NCBI Gene',NULL,NULL,NULL,NULL,NULL,NULL,'https://www.ncbi.nlm.nih.gov/gene/4988','https://www.ncbi.nlm.nih.gov/gene/4988','authoritative_database_record','Homo sapiens','published','none_known','public_web_access',NULL,'structured_fields_extracted','{"archive_status":"metadata_and_excerpt_only","database":"NCBI Gene","retrieved_at":"2026-07-25T10:50:28-04:00","source_file_sha256":null,"source_id":"SRC-OPRM1-NCBI_GENE","source_type":"authoritative_database_record","species":"Homo sapiens","title":"OPRM1 opioid receptor mu 1 [Homo sapiens]","url":"https://www.ncbi.nlm.nih.gov/gene/4988"}','Module 1A identifier seed','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_versions" VALUES('SRC-OPRM1-UNIPROT-v1','SRC-OPRM1-UNIPROT',1,NULL,'P35372 Mu-type opioid receptor Homo sapiens','[]','UniProtKB/Swiss-Prot',NULL,NULL,NULL,NULL,NULL,NULL,'https://www.uniprot.org/uniprotkb/P35372/entry','https://www.uniprot.org/uniprotkb/P35372/entry','authoritative_database_record','Homo sapiens','published','none_known','public_web_access',NULL,'structured_fields_extracted','{"archive_status":"metadata_and_excerpt_only","database":"UniProtKB/Swiss-Prot","retrieved_at":"2026-07-25T10:50:28-04:00","source_file_sha256":null,"source_id":"SRC-OPRM1-UNIPROT","source_type":"authoritative_database_record","species":"Homo sapiens","title":"P35372 Mu-type opioid receptor Homo sapiens","url":"https://www.uniprot.org/uniprotkb/P35372/entry"}','Module 1A identifier seed','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_versions" VALUES('SRC-OPRM1-IUPHAR-v1','SRC-OPRM1-IUPHAR',1,NULL,'μ receptor | Opioid receptors','[]','IUPHAR/BPS Guide to PHARMACOLOGY',NULL,NULL,NULL,NULL,NULL,NULL,'https://www.guidetopharmacology.org/GRAC/ObjectDisplayForward?objectId=319','https://www.guidetopharmacology.org/GRAC/ObjectDisplayForward?objectId=319','authoritative_database_record','Homo sapiens','published','none_known','public_web_access',NULL,'structured_fields_extracted','{"archive_status":"metadata_and_excerpt_only","database":"IUPHAR/BPS Guide to PHARMACOLOGY","retrieved_at":"2026-07-25T10:50:28-04:00","source_file_sha256":null,"source_id":"SRC-OPRM1-IUPHAR","source_type":"authoritative_database_record","species":"Homo sapiens","title":"μ receptor | Opioid receptors","url":"https://www.guidetopharmacology.org/GRAC/ObjectDisplayForward?objectId=319"}','Module 1A identifier seed','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_versions" VALUES('SRC-OPRD1-NCBI_GENE-v1','SRC-OPRD1-NCBI_GENE',1,NULL,'OPRD1 opioid receptor delta 1 [Homo sapiens]','[]','NCBI Gene',NULL,NULL,NULL,NULL,NULL,NULL,'https://www.ncbi.nlm.nih.gov/gene/4985','https://www.ncbi.nlm.nih.gov/gene/4985','authoritative_database_record','Homo sapiens','published','none_known','public_web_access',NULL,'structured_fields_extracted','{"archive_status":"metadata_and_excerpt_only","database":"NCBI Gene","retrieved_at":"2026-07-25T10:50:28-04:00","source_file_sha256":null,"source_id":"SRC-OPRD1-NCBI_GENE","source_type":"authoritative_database_record","species":"Homo sapiens","title":"OPRD1 opioid receptor delta 1 [Homo sapiens]","url":"https://www.ncbi.nlm.nih.gov/gene/4985"}','Module 1A identifier seed','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_versions" VALUES('SRC-OPRD1-UNIPROT-v1','SRC-OPRD1-UNIPROT',1,NULL,'P41143 Delta-type opioid receptor Homo sapiens','[]','UniProtKB/Swiss-Prot',NULL,NULL,NULL,NULL,NULL,NULL,'https://www.uniprot.org/uniprotkb/P41143/entry','https://www.uniprot.org/uniprotkb/P41143/entry','authoritative_database_record','Homo sapiens','published','none_known','public_web_access',NULL,'structured_fields_extracted','{"archive_status":"metadata_and_excerpt_only","database":"UniProtKB/Swiss-Prot","retrieved_at":"2026-07-25T10:50:28-04:00","source_file_sha256":null,"source_id":"SRC-OPRD1-UNIPROT","source_type":"authoritative_database_record","species":"Homo sapiens","title":"P41143 Delta-type opioid receptor Homo sapiens","url":"https://www.uniprot.org/uniprotkb/P41143/entry"}','Module 1A identifier seed','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_versions" VALUES('SRC-OPRD1-IUPHAR-v1','SRC-OPRD1-IUPHAR',1,NULL,'δ receptor | Opioid receptors','[]','IUPHAR/BPS Guide to PHARMACOLOGY',NULL,NULL,NULL,NULL,NULL,NULL,'https://www.guidetopharmacology.org/GRAC/ObjectDisplayForward?objectId=317','https://www.guidetopharmacology.org/GRAC/ObjectDisplayForward?objectId=317','authoritative_database_record','Homo sapiens','published','none_known','public_web_access',NULL,'structured_fields_extracted','{"archive_status":"metadata_and_excerpt_only","database":"IUPHAR/BPS Guide to PHARMACOLOGY","retrieved_at":"2026-07-25T10:50:28-04:00","source_file_sha256":null,"source_id":"SRC-OPRD1-IUPHAR","source_type":"authoritative_database_record","species":"Homo sapiens","title":"δ receptor | Opioid receptors","url":"https://www.guidetopharmacology.org/GRAC/ObjectDisplayForward?objectId=317"}','Module 1A identifier seed','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_versions" VALUES('SRC-OPRK1-NCBI_GENE-v1','SRC-OPRK1-NCBI_GENE',1,NULL,'OPRK1 opioid receptor kappa 1 [Homo sapiens]','[]','NCBI Gene',NULL,NULL,NULL,NULL,NULL,NULL,'https://www.ncbi.nlm.nih.gov/gene/4986','https://www.ncbi.nlm.nih.gov/gene/4986','authoritative_database_record','Homo sapiens','published','none_known','public_web_access',NULL,'structured_fields_extracted','{"archive_status":"metadata_and_excerpt_only","database":"NCBI Gene","retrieved_at":"2026-07-25T10:50:28-04:00","source_file_sha256":null,"source_id":"SRC-OPRK1-NCBI_GENE","source_type":"authoritative_database_record","species":"Homo sapiens","title":"OPRK1 opioid receptor kappa 1 [Homo sapiens]","url":"https://www.ncbi.nlm.nih.gov/gene/4986"}','Module 1A identifier seed','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_versions" VALUES('SRC-OPRK1-UNIPROT-v1','SRC-OPRK1-UNIPROT',1,NULL,'P41145 Kappa-type opioid receptor Homo sapiens','[]','UniProtKB/Swiss-Prot',NULL,NULL,NULL,NULL,NULL,NULL,'https://www.uniprot.org/uniprotkb/P41145/entry','https://www.uniprot.org/uniprotkb/P41145/entry','authoritative_database_record','Homo sapiens','published','none_known','public_web_access',NULL,'structured_fields_extracted','{"archive_status":"metadata_and_excerpt_only","database":"UniProtKB/Swiss-Prot","retrieved_at":"2026-07-25T10:50:28-04:00","source_file_sha256":null,"source_id":"SRC-OPRK1-UNIPROT","source_type":"authoritative_database_record","species":"Homo sapiens","title":"P41145 Kappa-type opioid receptor Homo sapiens","url":"https://www.uniprot.org/uniprotkb/P41145/entry"}','Module 1A identifier seed','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_versions" VALUES('SRC-OPRK1-IUPHAR-v1','SRC-OPRK1-IUPHAR',1,NULL,'κ receptor | Opioid receptors','[]','IUPHAR/BPS Guide to PHARMACOLOGY',NULL,NULL,NULL,NULL,NULL,NULL,'https://www.guidetopharmacology.org/GRAC/ObjectDisplayForward?objectId=318','https://www.guidetopharmacology.org/GRAC/ObjectDisplayForward?objectId=318','authoritative_database_record','Homo sapiens','published','none_known','public_web_access',NULL,'structured_fields_extracted','{"archive_status":"metadata_and_excerpt_only","database":"IUPHAR/BPS Guide to PHARMACOLOGY","retrieved_at":"2026-07-25T10:50:28-04:00","source_file_sha256":null,"source_id":"SRC-OPRK1-IUPHAR","source_type":"authoritative_database_record","species":"Homo sapiens","title":"κ receptor | Opioid receptors","url":"https://www.guidetopharmacology.org/GRAC/ObjectDisplayForward?objectId=318"}','Module 1A identifier seed','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_versions" VALUES('SRC-OPRL1-NCBI_GENE-v1','SRC-OPRL1-NCBI_GENE',1,NULL,'OPRL1 opioid related nociceptin receptor 1 [Homo sapiens]','[]','NCBI Gene',NULL,NULL,NULL,NULL,NULL,NULL,'https://www.ncbi.nlm.nih.gov/gene/4987','https://www.ncbi.nlm.nih.gov/gene/4987','authoritative_database_record','Homo sapiens','published','none_known','public_web_access',NULL,'structured_fields_extracted','{"archive_status":"metadata_and_excerpt_only","database":"NCBI Gene","retrieved_at":"2026-07-25T10:50:28-04:00","source_file_sha256":null,"source_id":"SRC-OPRL1-NCBI_GENE","source_type":"authoritative_database_record","species":"Homo sapiens","title":"OPRL1 opioid related nociceptin receptor 1 [Homo sapiens]","url":"https://www.ncbi.nlm.nih.gov/gene/4987"}','Module 1A identifier seed','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_versions" VALUES('SRC-OPRL1-UNIPROT-v1','SRC-OPRL1-UNIPROT',1,NULL,'P41146 Nociceptin receptor Homo sapiens','[]','UniProtKB/Swiss-Prot',NULL,NULL,NULL,NULL,NULL,NULL,'https://www.uniprot.org/uniprotkb/P41146/entry','https://www.uniprot.org/uniprotkb/P41146/entry','authoritative_database_record','Homo sapiens','published','none_known','public_web_access',NULL,'structured_fields_extracted','{"archive_status":"metadata_and_excerpt_only","database":"UniProtKB/Swiss-Prot","retrieved_at":"2026-07-25T10:50:28-04:00","source_file_sha256":null,"source_id":"SRC-OPRL1-UNIPROT","source_type":"authoritative_database_record","species":"Homo sapiens","title":"P41146 Nociceptin receptor Homo sapiens","url":"https://www.uniprot.org/uniprotkb/P41146/entry"}','Module 1A identifier seed','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_versions" VALUES('SRC-OPRL1-IUPHAR-v1','SRC-OPRL1-IUPHAR',1,NULL,'NOP receptor | Opioid receptors','[]','IUPHAR/BPS Guide to PHARMACOLOGY',NULL,NULL,NULL,NULL,NULL,NULL,'https://www.guidetopharmacology.org/GRAC/ObjectDisplayForward?objectId=320','https://www.guidetopharmacology.org/GRAC/ObjectDisplayForward?objectId=320','authoritative_database_record','Homo sapiens','published','none_known','public_web_access',NULL,'structured_fields_extracted','{"archive_status":"metadata_and_excerpt_only","database":"IUPHAR/BPS Guide to PHARMACOLOGY","retrieved_at":"2026-07-25T10:50:28-04:00","source_file_sha256":null,"source_id":"SRC-OPRL1-IUPHAR","source_type":"authoritative_database_record","species":"Homo sapiens","title":"NOP receptor | Opioid receptors","url":"https://www.guidetopharmacology.org/GRAC/ObjectDisplayForward?objectId=320"}','Module 1A identifier seed','ocsa-20260725-module1-receptor-identifiers-001','2026-07-25T20:54:24+00:00');
INSERT INTO "source_versions" VALUES('SRC-OPRM1-NCBI_GENE-v2','SRC-OPRM1-NCBI_GENE',2,'SRC-OPRM1-NCBI_GENE-v1','OPRM1 opioid receptor mu 1 [Homo sapiens]','[]','NCBI Gene',NULL,NULL,NULL,NULL,NULL,NULL,'https://www.ncbi.nlm.nih.gov/gene/4988','https://www.ncbi.nlm.nih.gov/gene/4988','authoritative_database_record','Homo sapiens','published','not_applicable_database_record','public_web_access',NULL,'structured_fields_extracted','{"archive_status":"metadata_and_excerpt_only","correction_retraction_status":"not_applicable_database_record","database":"NCBI Gene","extraction_status":"structured_fields_extracted","license_or_access_status":"public_web_access","notes":"Full immutable page capture was not archived; canonical acceptance is blocked.","retrieved_at":"2026-07-25T10:50:28-04:00","source_file_sha256":null,"source_id":"SRC-OPRM1-NCBI_GENE","source_type":"authoritative_database_record","species":"Homo sapiens","title":"OPRM1 opioid receptor mu 1 [Homo sapiens]","url":"https://www.ncbi.nlm.nih.gov/gene/4988"}','Archived staging metadata reconciliation; source not re-authenticated','ocsa-20261011-module1a-metadata-reconciliation-001','2026-10-11T16:55:41+00:00');
INSERT INTO "source_versions" VALUES('SRC-OPRM1-UNIPROT-v2','SRC-OPRM1-UNIPROT',2,'SRC-OPRM1-UNIPROT-v1','P35372 Mu-type opioid receptor Homo sapiens','[]','UniProtKB/Swiss-Prot',NULL,NULL,NULL,NULL,NULL,NULL,'https://www.uniprot.org/uniprotkb/P35372/entry','https://www.uniprot.org/uniprotkb/P35372/entry','authoritative_database_record','Homo sapiens','published','not_applicable_database_record','public_web_access',NULL,'structured_fields_extracted','{"archive_status":"metadata_and_excerpt_only","correction_retraction_status":"not_applicable_database_record","database":"UniProtKB/Swiss-Prot","extraction_status":"structured_fields_extracted","license_or_access_status":"public_web_access","notes":"Full immutable page capture was not archived; canonical acceptance is blocked.","retrieved_at":"2026-07-25T10:50:28-04:00","source_file_sha256":null,"source_id":"SRC-OPRM1-UNIPROT","source_type":"authoritative_database_record","species":"Homo sapiens","title":"P35372 Mu-type opioid receptor Homo sapiens","url":"https://www.uniprot.org/uniprotkb/P35372/entry"}','Archived staging metadata reconciliation; source not re-authenticated','ocsa-20261011-module1a-metadata-reconciliation-001','2026-10-11T16:55:41+00:00');
INSERT INTO "source_versions" VALUES('SRC-OPRM1-IUPHAR-v2','SRC-OPRM1-IUPHAR',2,'SRC-OPRM1-IUPHAR-v1','μ receptor | Opioid receptors','[]','IUPHAR/BPS Guide to PHARMACOLOGY',NULL,NULL,NULL,NULL,NULL,NULL,'https://www.guidetopharmacology.org/GRAC/ObjectDisplayForward?objectId=319','https://www.guidetopharmacology.org/GRAC/ObjectDisplayForward?objectId=319','authoritative_database_record','Homo sapiens','published','not_applicable_database_record','public_web_access',NULL,'structured_fields_extracted','{"archive_status":"metadata_and_excerpt_only","correction_retraction_status":"not_applicable_database_record","database":"IUPHAR/BPS Guide to PHARMACOLOGY","extraction_status":"structured_fields_extracted","license_or_access_status":"public_web_access","notes":"Full immutable page capture was not archived; canonical acceptance is blocked.","retrieved_at":"2026-07-25T10:50:28-04:00","source_file_sha256":null,"source_id":"SRC-OPRM1-IUPHAR","source_type":"authoritative_database_record","species":"Homo sapiens","title":"μ receptor | Opioid receptors","url":"https://www.guidetopharmacology.org/GRAC/ObjectDisplayForward?objectId=319"}','Archived staging metadata reconciliation; source not re-authenticated','ocsa-20261011-module1a-metadata-reconciliation-001','2026-10-11T16:55:41+00:00');
INSERT INTO "source_versions" VALUES('SRC-OPRD1-NCBI_GENE-v2','SRC-OPRD1-NCBI_GENE',2,'SRC-OPRD1-NCBI_GENE-v1','OPRD1 opioid receptor delta 1 [Homo sapiens]','[]','NCBI Gene',NULL,NULL,NULL,NULL,NULL,NULL,'https://www.ncbi.nlm.nih.gov/gene/4985','https://www.ncbi.nlm.nih.gov/gene/4985','authoritative_database_record','Homo sapiens','published','not_applicable_database_record','public_web_access',NULL,'structured_fields_extracted','{"archive_status":"metadata_and_excerpt_only","correction_retraction_status":"not_applicable_database_record","database":"NCBI Gene","extraction_status":"structured_fields_extracted","license_or_access_status":"public_web_access","notes":"Full immutable page capture was not archived; canonical acceptance is blocked.","retrieved_at":"2026-07-25T10:50:28-04:00","source_file_sha256":null,"source_id":"SRC-OPRD1-NCBI_GENE","source_type":"authoritative_database_record","species":"Homo sapiens","title":"OPRD1 opioid receptor delta 1 [Homo sapiens]","url":"https://www.ncbi.nlm.nih.gov/gene/4985"}','Archived staging metadata reconciliation; source not re-authenticated','ocsa-20261011-module1a-metadata-reconciliation-001','2026-10-11T16:55:41+00:00');
INSERT INTO "source_versions" VALUES('SRC-OPRD1-UNIPROT-v2','SRC-OPRD1-UNIPROT',2,'SRC-OPRD1-UNIPROT-v1','P41143 Delta-type opioid receptor Homo sapiens','[]','UniProtKB/Swiss-Prot',NULL,NULL,NULL,NULL,NULL,NULL,'https://www.uniprot.org/uniprotkb/P41143/entry','https://www.uniprot.org/uniprotkb/P41143/entry','authoritative_database_record','Homo sapiens','published','not_applicable_database_record','public_web_access',NULL,'structured_fields_extracted','{"archive_status":"metadata_and_excerpt_only","correction_retraction_status":"not_applicable_database_record","database":"UniProtKB/Swiss-Prot","extraction_status":"structured_fields_extracted","license_or_access_status":"public_web_access","notes":"Full immutable page capture was not archived; canonical acceptance is blocked.","retrieved_at":"2026-07-25T10:50:28-04:00","source_file_sha256":null,"source_id":"SRC-OPRD1-UNIPROT","source_type":"authoritative_database_record","species":"Homo sapiens","title":"P41143 Delta-type opioid receptor Homo sapiens","url":"https://www.uniprot.org/uniprotkb/P41143/entry"}','Archived staging metadata reconciliation; source not re-authenticated','ocsa-20261011-module1a-metadata-reconciliation-001','2026-10-11T16:55:41+00:00');
INSERT INTO "source_versions" VALUES('SRC-OPRD1-IUPHAR-v2','SRC-OPRD1-IUPHAR',2,'SRC-OPRD1-IUPHAR-v1','δ receptor | Opioid receptors','[]','IUPHAR/BPS Guide to PHARMACOLOGY',NULL,NULL,NULL,NULL,NULL,NULL,'https://www.guidetopharmacology.org/GRAC/ObjectDisplayForward?familyId=50&objectId=317','https://www.guidetopharmacology.org/GRAC/ObjectDisplayForward?familyId=50&objectId=317','authoritative_database_record','Homo sapiens','published','not_applicable_database_record','public_web_access',NULL,'structured_fields_extracted','{"archive_status":"metadata_and_excerpt_only","correction_retraction_status":"not_applicable_database_record","database":"IUPHAR/BPS Guide to PHARMACOLOGY","extraction_status":"structured_fields_extracted","license_or_access_status":"public_web_access","notes":"Full immutable page capture was not archived; canonical acceptance is blocked.","retrieved_at":"2026-07-25T10:50:28-04:00","source_file_sha256":null,"source_id":"SRC-OPRD1-IUPHAR","source_type":"authoritative_database_record","species":"Homo sapiens","title":"δ receptor | Opioid receptors","url":"https://www.guidetopharmacology.org/GRAC/ObjectDisplayForward?familyId=50&objectId=317"}','Archived staging metadata reconciliation; source not re-authenticated','ocsa-20261011-module1a-metadata-reconciliation-001','2026-10-11T16:55:41+00:00');
INSERT INTO "source_versions" VALUES('SRC-OPRK1-NCBI_GENE-v2','SRC-OPRK1-NCBI_GENE',2,'SRC-OPRK1-NCBI_GENE-v1','OPRK1 opioid receptor kappa 1 [Homo sapiens]','[]','NCBI Gene',NULL,NULL,NULL,NULL,NULL,NULL,'https://www.ncbi.nlm.nih.gov/gene/4986','https://www.ncbi.nlm.nih.gov/gene/4986','authoritative_database_record','Homo sapiens','published','not_applicable_database_record','public_web_access',NULL,'structured_fields_extracted','{"archive_status":"metadata_and_excerpt_only","correction_retraction_status":"not_applicable_database_record","database":"NCBI Gene","extraction_status":"structured_fields_extracted","license_or_access_status":"public_web_access","notes":"Full immutable page capture was not archived; canonical acceptance is blocked.","retrieved_at":"2026-07-25T10:50:28-04:00","source_file_sha256":null,"source_id":"SRC-OPRK1-NCBI_GENE","source_type":"authoritative_database_record","species":"Homo sapiens","title":"OPRK1 opioid receptor kappa 1 [Homo sapiens]","url":"https://www.ncbi.nlm.nih.gov/gene/4986"}','Archived staging metadata reconciliation; source not re-authenticated','ocsa-20261011-module1a-metadata-reconciliation-001','2026-10-11T16:55:41+00:00');
INSERT INTO "source_versions" VALUES('SRC-OPRK1-UNIPROT-v2','SRC-OPRK1-UNIPROT',2,'SRC-OPRK1-UNIPROT-v1','P41145 Kappa-type opioid receptor Homo sapiens','[]','UniProtKB/Swiss-Prot',NULL,NULL,NULL,NULL,NULL,NULL,'https://www.uniprot.org/uniprotkb/P41145/entry','https://www.uniprot.org/uniprotkb/P41145/entry','authoritative_database_record','Homo sapiens','published','not_applicable_database_record','public_web_access',NULL,'structured_fields_extracted','{"archive_status":"metadata_and_excerpt_only","correction_retraction_status":"not_applicable_database_record","database":"UniProtKB/Swiss-Prot","extraction_status":"structured_fields_extracted","license_or_access_status":"public_web_access","notes":"Full immutable page capture was not archived; canonical acceptance is blocked.","retrieved_at":"2026-07-25T10:50:28-04:00","source_file_sha256":null,"source_id":"SRC-OPRK1-UNIPROT","source_type":"authoritative_database_record","species":"Homo sapiens","title":"P41145 Kappa-type opioid receptor Homo sapiens","url":"https://www.uniprot.org/uniprotkb/P41145/entry"}','Archived staging metadata reconciliation; source not re-authenticated','ocsa-20261011-module1a-metadata-reconciliation-001','2026-10-11T16:55:41+00:00');
INSERT INTO "source_versions" VALUES('SRC-OPRK1-IUPHAR-v2','SRC-OPRK1-IUPHAR',2,'SRC-OPRK1-IUPHAR-v1','κ receptor | Opioid receptors','[]','IUPHAR/BPS Guide to PHARMACOLOGY',NULL,NULL,NULL,NULL,NULL,NULL,'https://www.guidetopharmacology.org/GRAC/ObjectDisplayForward?objectId=318','https://www.guidetopharmacology.org/GRAC/ObjectDisplayForward?objectId=318','authoritative_database_record','Homo sapiens','published','not_applicable_database_record','public_web_access',NULL,'structured_fields_extracted','{"archive_status":"metadata_and_excerpt_only","correction_retraction_status":"not_applicable_database_record","database":"IUPHAR/BPS Guide to PHARMACOLOGY","extraction_status":"structured_fields_extracted","license_or_access_status":"public_web_access","notes":"Full immutable page capture was not archived; canonical acceptance is blocked.","retrieved_at":"2026-07-25T10:50:28-04:00","source_file_sha256":null,"source_id":"SRC-OPRK1-IUPHAR","source_type":"authoritative_database_record","species":"Homo sapiens","title":"κ receptor | Opioid receptors","url":"https://www.guidetopharmacology.org/GRAC/ObjectDisplayForward?objectId=318"}','Archived staging metadata reconciliation; source not re-authenticated','ocsa-20261011-module1a-metadata-reconciliation-001','2026-10-11T16:55:41+00:00');
INSERT INTO "source_versions" VALUES('SRC-OPRL1-NCBI_GENE-v2','SRC-OPRL1-NCBI_GENE',2,'SRC-OPRL1-NCBI_GENE-v1','OPRL1 opioid related nociceptin receptor 1 [Homo sapiens]','[]','NCBI Gene',NULL,NULL,NULL,NULL,NULL,NULL,'https://www.ncbi.nlm.nih.gov/gene/4987','https://www.ncbi.nlm.nih.gov/gene/4987','authoritative_database_record','Homo sapiens','published','not_applicable_database_record','public_web_access',NULL,'structured_fields_extracted','{"archive_status":"metadata_and_excerpt_only","correction_retraction_status":"not_applicable_database_record","database":"NCBI Gene","extraction_status":"structured_fields_extracted","license_or_access_status":"public_web_access","notes":"Full immutable page capture was not archived; canonical acceptance is blocked.","retrieved_at":"2026-07-25T10:50:28-04:00","source_file_sha256":null,"source_id":"SRC-OPRL1-NCBI_GENE","source_type":"authoritative_database_record","species":"Homo sapiens","title":"OPRL1 opioid related nociceptin receptor 1 [Homo sapiens]","url":"https://www.ncbi.nlm.nih.gov/gene/4987"}','Archived staging metadata reconciliation; source not re-authenticated','ocsa-20261011-module1a-metadata-reconciliation-001','2026-10-11T16:55:41+00:00');
INSERT INTO "source_versions" VALUES('SRC-OPRL1-UNIPROT-v2','SRC-OPRL1-UNIPROT',2,'SRC-OPRL1-UNIPROT-v1','P41146 Nociceptin receptor Homo sapiens','[]','UniProtKB/Swiss-Prot',NULL,NULL,NULL,NULL,NULL,NULL,'https://www.uniprot.org/uniprotkb/P41146/entry','https://www.uniprot.org/uniprotkb/P41146/entry','authoritative_database_record','Homo sapiens','published','not_applicable_database_record','public_web_access',NULL,'structured_fields_extracted','{"archive_status":"metadata_and_excerpt_only","correction_retraction_status":"not_applicable_database_record","database":"UniProtKB/Swiss-Prot","extraction_status":"structured_fields_extracted","license_or_access_status":"public_web_access","notes":"Full immutable page capture was not archived; canonical acceptance is blocked.","retrieved_at":"2026-07-25T10:50:28-04:00","source_file_sha256":null,"source_id":"SRC-OPRL1-UNIPROT","source_type":"authoritative_database_record","species":"Homo sapiens","title":"P41146 Nociceptin receptor Homo sapiens","url":"https://www.uniprot.org/uniprotkb/P41146/entry"}','Archived staging metadata reconciliation; source not re-authenticated','ocsa-20261011-module1a-metadata-reconciliation-001','2026-10-11T16:55:41+00:00');
INSERT INTO "source_versions" VALUES('SRC-OPRL1-IUPHAR-v2','SRC-OPRL1-IUPHAR',2,'SRC-OPRL1-IUPHAR-v1','NOP receptor | Opioid receptors','[]','IUPHAR/BPS Guide to PHARMACOLOGY',NULL,NULL,NULL,NULL,NULL,NULL,'https://www.guidetopharmacology.org/GRAC/ObjectDisplayForward?objectId=320','https://www.guidetopharmacology.org/GRAC/ObjectDisplayForward?objectId=320','authoritative_database_record','Homo sapiens','published','not_applicable_database_record','public_web_access',NULL,'structured_fields_extracted','{"archive_status":"metadata_and_excerpt_only","correction_retraction_status":"not_applicable_database_record","database":"IUPHAR/BPS Guide to PHARMACOLOGY","extraction_status":"structured_fields_extracted","license_or_access_status":"public_web_access","notes":"Full immutable page capture was not archived; canonical acceptance is blocked.","retrieved_at":"2026-07-25T10:50:28-04:00","source_file_sha256":null,"source_id":"SRC-OPRL1-IUPHAR","source_type":"authoritative_database_record","species":"Homo sapiens","title":"NOP receptor | Opioid receptors","url":"https://www.guidetopharmacology.org/GRAC/ObjectDisplayForward?objectId=320"}','Archived staging metadata reconciliation; source not re-authenticated','ocsa-20261011-module1a-metadata-reconciliation-001','2026-10-11T16:55:41+00:00');
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
INSERT INTO "validation_runs" VALUES('val-a77e2a9e5ffd2cc7723f5c72','ocsa-20260725-module1-receptor-identifiers-001','0.2.2','3a3a855986f564a520c7cf103a8b2ae3f6413894b40640a45b35bcf6a131d28b',1,0,0,'2026-07-25T20:54:54+00:00','2026-07-25T20:54:54+00:00');
CREATE VIEW current_source_versions AS
SELECT sv.* FROM source_versions sv
WHERE NOT EXISTS (SELECT 1 FROM source_versions newer WHERE newer.supersedes_source_version_id=sv.source_version_id);
CREATE VIEW current_entity_versions AS
SELECT ev.* FROM entity_versions ev
WHERE NOT EXISTS (SELECT 1 FROM entity_versions newer WHERE newer.supersedes_entity_version_id=ev.entity_version_id);
CREATE VIEW current_claim_versions AS
SELECT cv.* FROM claim_versions cv
WHERE NOT EXISTS (SELECT 1 FROM claim_versions newer WHERE newer.supersedes_claim_version_id=cv.claim_version_id);
CREATE VIEW full_research_graph AS SELECT * FROM current_claim_versions;
CREATE VIEW provisional_graph AS SELECT * FROM current_claim_versions WHERE state NOT IN ('rejected','retracted','duplicate');
CREATE VIEW contradiction_graph AS
SELECT cv.* FROM contradiction_versions cv
WHERE NOT EXISTS (SELECT 1 FROM contradiction_versions newer WHERE newer.supersedes_contradiction_version_id=cv.contradiction_version_id);
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
CREATE UNIQUE INDEX one_successor_per_evidence_span ON evidence_spans(supersedes_evidence_span_id) WHERE supersedes_evidence_span_id IS NOT NULL;
CREATE UNIQUE INDEX one_successor_per_review ON claim_reviews(supersedes_review_id) WHERE supersedes_review_id IS NOT NULL;
CREATE VIEW current_evidence_spans AS SELECT ev.* FROM evidence_spans ev WHERE NOT EXISTS (SELECT 1 FROM evidence_spans newer WHERE newer.supersedes_evidence_span_id=ev.evidence_span_id);
CREATE VIEW current_claim_reviews AS SELECT cr.* FROM claim_reviews cr WHERE NOT EXISTS (SELECT 1 FROM claim_reviews newer WHERE newer.supersedes_review_id=cr.review_id);
CREATE VIEW canonical_graph AS SELECT cv.* FROM current_claim_versions cv
                WHERE cv.state='accepted' AND cv.review_tier>=2 AND cv.context_json<>'{}'
                AND EXISTS (SELECT 1 FROM claim_evidence ce JOIN evidence_spans es
                    ON es.evidence_span_id=ce.evidence_span_id JOIN source_files sf
                    ON sf.sha256=es.source_file_sha256 WHERE ce.claim_version_id=cv.claim_version_id)
                AND EXISTS (SELECT 1 FROM current_claim_reviews cr WHERE cr.claim_version_id=cv.claim_version_id
                    AND cr.review_pass=2 AND cr.independent=1 AND cr.result='agree')
                AND NOT EXISTS (SELECT 1 FROM claim_evidence ce JOIN evidence_spans es
                    ON es.evidence_span_id=ce.evidence_span_id LEFT JOIN source_authenticity_checks sac
                    ON sac.source_version_id=es.source_version_id AND sac.resolution_status='pass'
                    WHERE ce.claim_version_id=cv.claim_version_id AND sac.check_id IS NULL);
COMMIT;
