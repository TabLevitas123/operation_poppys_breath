# OCSA v0.2.1 infrastructure repair candidate

Run: `ocsa-20260724-module0-repair-002`  
Date: 2026-07-24  
Scientific claims accepted: 0

This candidate repairs the repository trust architecture after audit established that pull request #1 remained unmerged, deleted visible project files, depended on a one-use materialization workflow, and had failing GitHub Actions jobs before their first step.

The release contains a directly inspectable append-only schema, validators, corruption tests, deterministic exports, reports, manifests, a machine-readable changeset, and a self-verifying archive. The binary database and pre/staging/post snapshots are carried inside that archive and reconstructed through independently hashed Base64 parts; ordinary project files remain directly readable.

Remote GitHub Actions remains a blocking publication gate until a runner starts and executes the workflow. The candidate must not be treated as merged or canonical until that check passes and the pull request is merged.
