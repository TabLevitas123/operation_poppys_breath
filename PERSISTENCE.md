# Repository persistence contract

## Canonical storage

The GitHub repository `TabLevitas123/operation_poppys_breath` is the durable project store. The default branch and versioned releases are authoritative for resuming work.

`/mnt/data` is temporary working storage. A file that exists only there is not considered preserved.

## Required end-of-run behavior

Every completed or cleanly checkpointed run must push, as applicable:

1. source code and tests;
2. schema and configuration;
3. research protocols and ontology files;
4. source and search manifests;
5. paper dossiers and evidence-span records;
6. proposed, verified, disputed, rejected, and accepted claim records;
7. contradiction and open-question registers;
8. database snapshots and hashes;
9. graph and evidence-table exports;
10. validation, test, graph-diff, and run reports;
11. a machine-readable changeset; and
12. a versioned release archive with a verification manifest.

No run may claim that an artifact was pushed unless the repository path and commit are verified after the write.

## Required beginning-of-run behavior

Before modifying data:

1. inspect the default branch and relevant active branch;
2. read the README, protocol, schema, changelog, configuration, manifests, reports, and open questions;
3. identify the latest valid checkpoint and parent database hash;
4. restore any required binary artifacts from the repository or release archive; and
5. create a pre-run snapshot before staging mutations.

## Normal source versus recovery archive

The ordinary source tree must remain directly visible and cloneable. A chunked or compressed archive may be retained as a secondary disaster-recovery copy, but it must not replace the inspectable working tree.

The archive under `.bootstrap/hardened-source/` is therefore a backup. Its declared concatenated Base64 SHA-256 is `ad8b321dc2c7cfabbc9d9c6710061f10289603686fdbec2785809e39e82e0473`; the decoded tar.gz SHA-256 is `8bcc3a3b3c3e52dda85a77b1bb8aa0a088ba7ce75c0bf44f278f46df9d9e2192`.
