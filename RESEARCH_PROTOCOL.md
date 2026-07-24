# OCSA research and evidence protocol

Version: 0.2.1  
Status: infrastructure candidate

## Objective and safety boundary

OCSA maps the endogenous and exogenous opioid systems across exposure, pharmacokinetics, receptor state, transduction, intracellular signaling, ion channels, cellular excitability, synapses, circuits, organs, behavior, subjective human effects, acute toxicity, chronic adaptation, and clinical outcomes.

The harm-reduction question is whether positively valued or craving-suppressing opioid effects can be mechanistically separated from respiratory depression, airway failure, dangerous sedation, tolerance, physical dependence, compulsive reinforcement, overdose, and mortality.

The project does not design, synthesize, optimize, or provide production instructions for an illicit or untested drug.

## Scientific scope

The receptor foundation comprises MOR/MOP/OPRM1, DOR/DOP/OPRD1, KOR/KOP/OPRK1, and NOP/OPRL1. Historically opioid-associated targets such as sigma receptors and the opioid growth-factor receptor remain distinct entities.

The endogenous-peptide scope includes POMC-derived peptides, β-endorphin, Met-enkephalin, Leu-enkephalin, proenkephalin-derived peptides, dynorphin A, dynorphin B, α-neoendorphin, β-neoendorphin, nociceptin/orphanin FQ, and the disputed endogenous status of endomorphin-related peptides.

Cross-system expansion is evidence-triggered. Initial priorities are GABA, glutamate, dopamine, norepinephrine, serotonin, tryptophan and kynurenine metabolism, acetylcholine, cannabinoid receptors and endocannabinoids, followed by mechanistically connected neuropeptide, endocrine, immune, metabolic, glial, autonomic, respiratory, pain, reward, learning, dependence, and withdrawal systems.

## Required mechanistic chain

Where evidence permits, claims should connect the following without skipping intermediate mechanisms:

1. exposure and route;
2. absorption and distribution;
3. blood-brain-barrier penetration;
4. metabolism and active metabolites;
5. receptor binding;
6. receptor conformation;
7. transducer recruitment;
8. intracellular signaling;
9. ion-channel and transporter effects;
10. receptor trafficking;
11. cellular excitability;
12. transmitter or peptide release;
13. synaptic and microcircuit effects;
14. long-range circuit effects;
15. organ and physiological effects;
16. behavioral effects;
17. subjective human effects;
18. acute toxicity;
19. chronic adaptation; and
20. clinical and population outcomes.

Acute signaling and chronic adaptation are modeled separately. Context records preserve first exposure, acute exposure, repeated intermittent or continuous exposure, escalation, tolerance, dependence, withdrawal, abstinence, loss of tolerance, re-exposure, chronic pain, opioid-induced hyperalgesia, opioid-use disorder, and medication treatment.

## Outcome separation

The atlas does not collapse pleasure, rush, emotional relief, withdrawal relief, pain relief, reward, incentive salience, reinforcement, conditioned learning, craving, drug seeking, compulsive use, analgesia, sedation, anxiolysis, dissociation, respiratory rhythm suppression, respiratory pattern disruption, chemoreflex impairment, upper-airway obstruction, reduced arousal, cough suppression, aspiration, nausea, constipation, endocrine effects, immune effects, tolerance, dependence, withdrawal, sensitization, hyperalgesia, overdose, and mortality into a generic “opioid effect.”

Analgesia is not a proxy for euphoria, subjective acceptability, craving suppression, or reinforcement.

## Literature discovery and saturation

Every scientific run records each database, search string, filter, and search date. Discovery systems should include, where available, PubMed/MEDLINE, PubMed Central, Europe PMC, Crossref, OpenAlex, ClinicalTrials.gov, bioRxiv, medRxiv, FDA, EMA, NIH and institutional repositories, dissertations, conference proceedings, patents, IUPHAR, GPCRdb, ChEMBL, UniProt, PDB, Allen Brain Atlas, Human Protein Atlas, Reactome, Gene Ontology, and relevant omics, single-cell, connectomic, pharmacokinetic, and genetic datasets.

Primary sources support scientific claims. Reviews are orientation and citation-chaining aids. Each major retained source receives backward and forward citation chaining, related-article searching, author and laboratory searching, exact construct or assay searching, replication and non-replication searching, correction and retraction checking, supplementary-material searching, and a search for corresponding human evidence.

Saturation is dated and provisional. It may be declared only after multiple independent formulations stop yielding major mechanisms, citation chains and key laboratories are reviewed, foundational references are represented, and exclusions and inaccessible full texts are documented.

## Source acquisition

Openly accessible source files, supplements, datasets, regulatory documents, patents, structures, and author manuscripts are stored immutably by content hash. A new or corrected document is a new source version linked to its predecessor. Paywalls and access controls are never bypassed. Inaccessible full text receives complete citation metadata, a lawful abstract when available, an access-status record, alternative-copy searching, and an entry in the missing-full-text register.

## Evidence model

Every accepted claim points to an exact evidence span containing the source version, source-file SHA-256, page or equivalent locator, excerpt, excerpt hash, evidence role, and extraction method. Evidence roles distinguish direct experimental results, numerical results, methods, author interpretation, background statements, review summaries, curator inference, and computational prediction.

Reported observation, authors’ interpretation, and curator synthesis are stored separately. Discussion hypotheses are not represented as measured results.

A citation is checked for authenticity, evidence existence, entailment, scope, and causal wording. Context includes all available species, strain, sex, age, genotype, disease and pain state, tolerance or withdrawal state, tissue, region, cell type, projection, subcellular compartment, ligand, metabolite, concentration, dose, route, schedule, duration, time point, assay, comparator, sample size, numerical effect, uncertainty, and risk of bias.

## Claim lifecycle

Allowed states are `proposed`, `source_verified`, `evidence_anchored`, `extraction_verified`, `reviewed`, `accepted`, `disputed`, `rejected`, `superseded`, `retracted`, `duplicate`, and `insufficient_evidence`.

The first version of every claim is `proposed`. Corrections and state changes create new immutable versions linked to the immediately preceding version. Only current `accepted` claim versions that satisfy every canonical gate are exposed by `canonical_graph`.

## Causal language

`REQUIRED_FOR` requires appropriate loss-of-function or intervention evidence. `SUFFICIENT_FOR` requires gain-of-function or activation evidence. `CAUSES` requires a defensible causal manipulation. Correlation uses `ASSOCIATED_WITH`. Expression does not establish function. RNA does not establish protein, protein does not establish functional signaling, receptor binding does not establish behavior, in-vitro efficacy does not establish in-vivo safety, and animal evidence does not automatically generalize to humans.

## Independent verification

Pass 1 extracts observations, spans, and proposed claims. Pass 2 re-reads the source blind to the first pass’s reasoning and checks citation identity, excerpt identity, entailment, polarity, scope, context, causal wording, and numbers. Disagreement enters adjudication. Review tiers range from Tier 0 machine-extracted through Tier 4 expert-reviewed or strong consensus.

## Contradictions

Conflicting evidence is never deleted. Contradiction versions preserve claim IDs, sources, evidence spans, species, doses, assays, exposure conditions, possible explanations, replication status, and adjudication state. Candidate explanations include species, strain, sex, age, receptor reserve, intrinsic efficacy, kinetics, signaling bias, dose, route, acute versus chronic exposure, cell and region, assay amplification, anesthesia, sleep, pain and withdrawal state, compensation, reagent specificity, power, and publication bias.

## Versioning, snapshots, and release gates

Scientific and audit records are append-only. Each run has a unique ID, parent release, parent database hash when available, protocol hash, model and tool metadata, accessed sources, source hashes, record counts, validation results, reviewer decisions, and release timestamp. Run and change events form SHA-256 hash chains.

A run creates a pre-run snapshot, works in staging, validates, produces a graph diff, promotes transactionally only when blocking checks pass, creates a post-run snapshot, and produces deterministic exports and a versioned archive. Unexpected mass deletions or foundational changes halt promotion.

Release integrity requires passing structural, source, evidence, entity, semantic, logical, numerical, graph-diff, snapshot, and release checks; passing tests; deterministic exports; recorded hashes; intact prior releases; release notes; a changeset; and a clean restoration test.
