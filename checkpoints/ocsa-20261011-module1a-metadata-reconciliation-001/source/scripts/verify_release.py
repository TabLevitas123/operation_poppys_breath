from __future__ import annotations
import argparse, hashlib, json, subprocess, sys, tempfile, zipfile
from pathlib import Path, PurePosixPath

def sha(path:Path): return hashlib.sha256(path.read_bytes()).hexdigest()
def main():
    ap=argparse.ArgumentParser(); ap.add_argument('archive',type=Path); ap.add_argument('--output',type=Path); args=ap.parse_args(); archive=args.archive.resolve(); errors=[]
    with tempfile.TemporaryDirectory() as td:
        root=Path(td)
        try:
            with zipfile.ZipFile(archive) as z:
                for member in z.infolist():
                    p=PurePosixPath(member.filename)
                    if p.is_absolute() or '..' in p.parts: raise ValueError(f'unsafe path {member.filename}')
                    mode=(member.external_attr>>16)&0o170000
                    if mode in {0o120000,0o060000}: raise ValueError(f'link/device {member.filename}')
                bad=z.testzip()
                if bad: raise ValueError(f'CRC failure {bad}')
                z.extractall(root)
            manifest=json.loads((root/'release-manifest.json').read_text())
            for rec in manifest['files']:
                p=root/rec['path']
                if not p.is_file(): errors.append(f"missing {rec['path']}")
                elif p.stat().st_size!=rec['size_bytes'] or sha(p)!=rec['sha256']: errors.append(f"hash mismatch {rec['path']}")
            if sha(root/'atlas.db')!=manifest['database_sha256']: errors.append('database hash mismatch')
            if not errors:
                v=subprocess.run([sys.executable,'src/ocsa_store.py','--db','atlas.db','--schema','schema.sql','--root','.','validate'],cwd=root,text=True,capture_output=True)
                if v.returncode: errors.append('restored database validation failed: '+v.stdout+v.stderr)
                t=subprocess.run([sys.executable,'-m','unittest','discover','-s','tests','-v'],cwd=root,text=True,capture_output=True)
                if t.returncode: errors.append('restored tests failed: '+t.stdout+t.stderr)
        except Exception as exc: errors.append(str(exc))
    result={'archive':str(archive),'archive_sha256':sha(archive),'passed':not errors,'errors':errors}
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(result,sort_keys=True,indent=2)+'\n')
    print(json.dumps(result,sort_keys=True,indent=2)); return 0 if not errors else 1
if __name__=='__main__': raise SystemExit(main())
