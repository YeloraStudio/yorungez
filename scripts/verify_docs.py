"""Offline repository-document links, requirement coverage and archive integrity."""
from pathlib import Path
from urllib.parse import unquote, urlsplit
import hashlib
import os
import re

ROOT = Path(__file__).resolve().parents[1]
SKIP = {".git", ".local", "node_modules", ".next", ".next-preview", "bin", "obj", "generated", "__pycache__"}
documents = []
for directory, folders, files in os.walk(ROOT):
    folders[:] = [name for name in folders if name not in SKIP and not name.startswith(".next-")]
    documents.extend(Path(directory) / name for name in files if name.endswith(".md"))
errors = []
links = 0
pattern = re.compile(r"!?\[[^\]\n]*\]\((<[^>]+>|[^\s)]+)(?:\s+[^)]*)?\)")
for path in documents:
    if "arsiv" in path.parts:
        continue  # Historical source remains byte-for-byte untouched.
    body = path.read_text(encoding="utf-8-sig")
    for match in pattern.finditer(body):
        target = match[1].strip("<>")
        if urlsplit(target).scheme or target.startswith("#"):
            continue
        target = unquote(target.split("#")[0])
        if target:
            links += 1
            if not (path.parent / target).exists():
                errors.append(f"Missing target in {path.relative_to(ROOT)}: {target}")

requirements = (ROOT / "docs/urun-gereksinimleri.md").read_text(encoding="utf-8")
trace = (ROOT / "docs/teslimat-izlenebilirligi.md").read_text(encoding="utf-8")
for family, count in {"FR": 12, "UJ": 7, "AC": 14}.items():
    expected = {f"{family}-{index:02}" for index in range(1, count + 1)}
    actual = set(re.findall(rf"\b{family}-\d{{2}}\b", requirements))
    if actual != expected or not expected.issubset(set(re.findall(rf"\b{family}-\d{{2}}\b", trace))):
        errors.append(f"Requirement identity/trace coverage mismatch: {family}")

archive = ROOT / "docs/arsiv/OpenSky_Proje_Gereksinimleri_UX_v1.md"
if hashlib.sha256(archive.read_bytes()).hexdigest() != "6d748df5dd0777b5570401f1f5bb163b94c2d51567f55c7139b9d42fd4c7c1fc":
    errors.append("Original archive fingerprint changed")
if errors:
    raise SystemExit("\n".join(errors))
print(f"Verified {links} local document/file links, all 12 FR / 7 UJ / 14 AC identities and trace rows; original archive unchanged.")
