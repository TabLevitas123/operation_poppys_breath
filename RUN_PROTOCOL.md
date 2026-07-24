# OCSA run protocol

At the beginning of each run:

1. Inspect the default branch, open pull requests, checks, release artifacts, and current database metadata.
2. Read the README, research protocol, schema, changelog, configuration, validation workflow, source manifest, open-question register, and latest release notes.
3. Identify the last completed module, incomplete work, validation failures, contradictions, inaccessible sources, and unreviewed claims.
4. Create a run ID and pre-run snapshot, record the parent release and database hash, and open staging state.
5. Do not duplicate completed work unless validation establishes a defect.

During a scientific run:

1. Record databases, search strings, filters, dates, inclusion criteria, exclusion criteria, and saturation status.
2. Archive lawful source files immutably by SHA-256.
3. Create source versions, dossiers, exact evidence spans, and proposed claims.
4. Perform blind pass-2 verification and route disagreements to adjudication.
5. Preserve contexts and contradictions; never promote AI-generated text directly.

At the end of each run:

1. Generate graph diffs and halt on unexpected mass changes.
2. Run all validators and corruption tests against a clean database.
3. Promote only records that satisfy their state gates.
4. Create post-staging and post-run snapshots.
5. Export canonical, provisional, full-research, contradiction, source, and evidence tables deterministically.
6. Write a machine-readable changeset and human-readable run, validation, and test reports.
7. Create a versioned archive and verify restoration in a clean directory.
8. Update the changelog, manifests, release notes, and open-question register.
9. Commit and push only verified changes. Never claim a save, test, commit, push, check, or release that was not observed.
