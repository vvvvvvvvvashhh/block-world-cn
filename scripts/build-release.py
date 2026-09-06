"""Build an offline source-inclusive distribution from an explicit allowlist.
SPDX-License-Identifier: GPL-3.0-or-later
"""
from pathlib import Path
import argparse
import hashlib
import json
import re
import zipfile
from check import ROOT, validate


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", default="v0.1.0")
    args = parser.parse_args()
    if not re.fullmatch(r"v\d+\.\d+\.\d+(?:-[A-Za-z0-9.-]+)?", args.version):
        parser.error("Invalid release version")
    files = validate()
    lock = json.loads((ROOT / "dependencies.lock.json").read_text(encoding="utf-8"))
    archives = []
    for item in lock["artifacts"]:
        path = ROOT / "downloads" / item["file"]
        if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != item["sha256"]:
            raise SystemExit(f"Missing/invalid dependency: {item['file']}; run scripts/fetch-deps.ps1")
        archives.append(path)
    output = ROOT / "dist"
    output.mkdir(exist_ok=True)
    target = output / f"block-world-cn-{args.version}-windows-x64-offline.zip"
    prefix = f"block-world-cn-{args.version}"
    temporary = target.with_suffix(".partial.zip")
    with zipfile.ZipFile(temporary, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for path in files + archives:
            arcname = prefix + "/" + path.relative_to(ROOT).as_posix()
            archive.write(path, arcname, compress_type=zipfile.ZIP_STORED if path in archives else zipfile.ZIP_DEFLATED)
    with zipfile.ZipFile(temporary) as archive:
        assert archive.testzip() is None, "ZIP integrity failed"
        assert len(archive.namelist()) == len(files) + len(archives)
        assert not any("/worlds/" in n or "/backups/" in n or "/evidence/" in n for n in archive.namelist())
    temporary.replace(target)
    digest = hashlib.sha256(target.read_bytes()).hexdigest()
    (output / "SHA256SUMS.txt").write_text(f"{digest}  {target.name}\n", encoding="ascii")
    print(f"Built {target.name} ({target.stat().st_size:,} bytes), SHA256 {digest}")


if __name__ == "__main__":
    main()
