# Research-run update protocol

Each OCSA research run must update the same canonical workspace rather than
creating disconnected notes.

1. Open `atlas.db` and verify its schema version and dataset revision.
2. Add or update source records with stable identifiers.
3. Add paper dossiers and exact source locators.
4. Add normalized entities only after alias and identifier checks.
5. Convert supported findings into contextualized claims.
6. Record contradictory evidence and unresolved questions explicitly.
7. Run integrity validation and the automated test suite.
8. Export JSONL and GraphML snapshots.
9. Rebuild or queue retrieval embeddings for changed documents.
10. Update the changelog and cryptographic manifest.
11. Create a timestamped snapshot and overwrite `OCSA_latest.zip`.
12. Return links to the latest archive, database, graph, and changelog.

`/mnt/data` is a working area, not a guaranteed permanent repository. Each
release should also be downloaded or copied to durable storage. Updates occur
only during an active research response; the workspace does not update in the
background.
