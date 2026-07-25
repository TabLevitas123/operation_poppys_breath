# OCSA Module 1A run report

Run ID: `ocsa-20260725-module1-receptor-identifiers-001`  
Date: 2026-07-25  
Parent checkpoint: `ocsa-20260724-module0-hardening-001`  
Scope: human opioid-receptor-family nomenclature and stable identifier seed only.

## Result

The four human receptor genes were mapped to approved gene identifiers, reviewed UniProt protein entries, IUPHAR receptor targets and GPCRdb entries. All twelve identity assertions remain `proposed`. The canonical graph was not changed.

| Receptor | Gene | HGNC | NCBI Gene | Ensembl | UniProt | IUPHAR | GPCRdb |
|---|---|---|---:|---|---|---:|---|
| MOR | OPRM1 | HGNC:8156 | 4988 | ENSG00000112038 | P35372 | 319 | oprm_human |
| DOR | OPRD1 | HGNC:8153 | 4985 | ENSG00000116329 | P41143 | 317 | oprd_human |
| KOR | OPRK1 | HGNC:8154 | 4986 | ENSG00000082556 | P41145 | 318 | oprk_human |
| NOP | OPRL1 | HGNC:8155 | 4987 | ENSG00000125510 | P41146 | 320 | oprx_human |

## Search accounting

- Databases: NCBI Gene, UniProtKB/Swiss-Prot, IUPHAR/BPS Guide to PHARMACOLOGY, and HGNC orientation.
- Screened candidates: 22.
- Retained evidence records: 12.
- Retained orientation records: 2.
- Excluded candidates: 8.
- Scientific papers: 0.
- Database-record dossiers: 12.
- Evidence spans: 12.
- Identity assertions proposed: 12.
- Pass-2 field verifications: 12.
- Accepted claims: 0.
- Contradictions: 0.
- Open questions: 4.
- Staging entities: 12.
- Proposed mapping edges: 8.
- Canonical nodes and edges added: 0.

## Terminology safeguard

`OPRL1`/NOP remains distinct from `OPRK1`/KOR. Historical aliases such as `KOR-3` are retained only as aliases and must never trigger an entity merge.

## Validation

Eighteen static integrity tests passed. Identifier formats and evidence hashes validate, all assertion states are proposed, and the canonical graph diff is zero.

## Blocking limitations

No immutable source-page files were archived, and the hardened SQLite database could not be materialized because the execution container could not resolve GitHub directly. No claim was accepted and no database promotion or release snapshot was attempted.

## Exact next start

Archive lawful source records or snapshots by content hash; restore the checkpoint database; ingest this staging package with proposed status; run the full structural, source, evidence, entity, semantic, logical, graph-diff and release validators; create pre-run and post-run snapshots.
