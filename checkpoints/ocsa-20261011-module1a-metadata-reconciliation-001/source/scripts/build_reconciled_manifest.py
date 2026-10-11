"""Record current staging bytes while retaining the discrepant historical manifest."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RUN = ROOT / "runs" / "ocsa-20260725-module1-receptor-identifiers-001"
OLD = RUN / "FILE_MANIFEST.json"
NEW = RUN / "FILE_MANIFEST_RECONCILED.json"

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    inner = json.loads(OLD.read_text())
    historical_outer = ROOT / "manifests/RELEASE_MANIFEST_PRE_RECONCILIATION.json"
    outer = json.loads(historical_outer.read_text())
    outer_files = {item["path"]: item for item in outer["files"]}
    files, mismatches = [], []
    for recorded in inner["files"]:
        path = ROOT / recorded["path"]
        if not path.is_file(): raise ValueError(f"Missing staged file: {path}")
        actual = {"path": recorded["path"], "sha256": digest(path), "size_bytes": path.stat().st_size}
        if actual != outer_files.get(actual["path"]):
            raise ValueError(f"Outer release manifest does not match current bytes: {path}")
        files.append(actual)
        if actual != recorded:
            mismatches.append({"path": actual["path"], "historical_record": recorded, "current_bytes": actual})
    expected = {"search_manifest.json", "source_manifest.json", "test_results.json"}
    if {Path(m["path"]).name for m in mismatches} != expected:
        raise ValueError("Unexpected historical manifest discrepancy set")
    result = {
        "status": "current_bytes_verified_historical_mismatch",
        "supersedes_manifest": OLD.relative_to(ROOT).as_posix(),
        "supersedes_manifest_sha256": digest(OLD),
        "outer_release_manifest_sha256": digest(historical_outer),
        "authenticates_historical_metadata": False,
        "external_source_reauthentication": "not_performed",
        "interpretation": "Hashes identify bytes in this archived copy only. The prior inner entries remain historical and inconsistent; neither manifest authenticates the biological contents or proves when bytes changed.",
        "historical_mismatches": mismatches,
        "files": files,
    }
    NEW.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(json.dumps({"manifest": str(NEW), "mismatches": len(mismatches), "files": len(files)}))

if __name__ == "__main__": main()
