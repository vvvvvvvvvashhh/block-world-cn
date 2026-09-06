"""Validate publishable source, path mappings, and community documents.
SPDX-License-Identifier: GPL-3.0-or-later
"""
from pathlib import Path
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
ROOT_FILES = [
    "README.md", "LICENSE", "NOTICE.md", "CONTRIBUTING.md", "CODE_OF_CONDUCT.md",
    "SECURITY.md", "CHANGELOG.md", "Start.cmd", "一键启动.cmd", ".gitignore",
    ".gitattributes", "dependencies.lock.json", "overrides.json",
]
SOURCE_DIRS = ["src", "assets", "scripts", "docs", "licenses", ".github"]


def publish_files():
    files = [ROOT / name for name in ROOT_FILES]
    for name in SOURCE_DIRS:
        files += [p for p in (ROOT / name).rglob("*") if p.is_file() and "__pycache__" not in p.parts]
    return sorted(files)


def validate():
    files = publish_files()
    for path in files:
        assert path.is_file(), f"Missing: {path.relative_to(ROOT)}"
        assert path.suffix not in {".sqlite", ".db", ".log", ".exe", ".dll", ".pyc"}, f"Runtime/private file in source: {path.name}"
        assert not path.is_symlink(), f"Symlink in release allowlist: {path.name}"
        if path.suffix != ".png":
            text = path.read_text(encoding="utf-8-sig")
            assert not re.search(r"[A-Za-z]:[\\/]Users[\\/][^\s]+", text), f"Local user path: {path.name}"
            assert not re.search(r"(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,})", text), f"Possible credential: {path.name}"
    targets = set()
    for item in json.loads((ROOT / "overrides.json").read_text(encoding="utf-8")):
        for field in ["source", "target"]:
            value = item[field]
            assert not Path(value).is_absolute() and ".." not in Path(value).parts and ":" not in value, "Unsafe override mapping"
        assert item["target"] not in targets, "Duplicate deployment target"
        targets.add(item["target"])
        assert (ROOT / item["source"]).is_file(), "Missing override source"
    lock = json.loads((ROOT / "dependencies.lock.json").read_text(encoding="utf-8"))
    assert lock["engine_version"] == "5.17.0" and lock["game_version"] == "0.123.1"
    names = set()
    for item in lock["artifacts"]:
        assert item["file"] == Path(item["file"]).name and item["file"] not in names
        names.add(item["file"])
        assert item["url"].startswith("https://") and re.fullmatch(r"[a-f0-9]{64}", item["sha256"])
    assert "[INSERT CONTACT METHOD]" not in (ROOT / "CODE_OF_CONDUCT.md").read_text(encoding="utf-8")
    for name in ["bug_report.yml", "feature_request.yml"]:
        text = (ROOT / ".github/ISSUE_TEMPLATE" / name).read_text(encoding="utf-8")
        assert "name:" in text and "description:" in text and "body:" in text
    print(f"PASS: {len(files)} publishable files, {len(targets)} mappings, {len(names)} pinned archives; no private runtime data.")
    return files


if __name__ == "__main__":
    try:
        validate()
    except (AssertionError, ValueError, OSError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        raise SystemExit(1)
