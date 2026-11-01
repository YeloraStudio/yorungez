"""Inspect exactly the Git index for forbidden files and leaked local secrets.

No matched value is ever printed. This complements Gitleaks; it is not a
guarantee that every possible secret or vulnerability has been identified.
"""
from pathlib import Path, PurePosixPath
import json
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def indexed_blobs():
    listing = subprocess.check_output(["git", "ls-files", "--stage", "-z"], cwd=ROOT)
    rows = []
    for item in listing.split(b"\0"):
        if not item:
            continue
        info, name = item.split(b"\t", 1)
        mode, sha, stage = info.split()
        if stage != b"0":
            raise SystemExit("Resolve index conflicts before publishing.")
        rows.append((name.decode("utf-8"), sha, mode))
    if not rows:
        raise SystemExit("No indexed files. Stage the reviewed public files first.")
    result = subprocess.run(["git", "cat-file", "--batch"], cwd=ROOT,
                            input=b"\n".join(sha for _, sha, _ in rows) + b"\n",
                            stdout=subprocess.PIPE, check=True).stdout
    cursor = 0
    for name, _, mode in rows:
        end = result.index(b"\n", cursor)
        _, kind, size = result[cursor:end].split()
        size = int(size)
        if kind != b"blob":
            raise SystemExit("Submodules are not part of the reviewed publication package.")
        body = result[end + 1:end + 1 + size]
        cursor = end + 1 + size + 1
        yield name, mode, body


def forbidden_path(name):
    p = PurePosixPath(name.lower())
    if any(part in {".local", ".vs", ".git", "node_modules", "bin", "obj", "testresults",
                    "secrets", "backups", "data-protection-keys", "portainer"}
           or part.startswith(".next") for part in p.parts):
        return True
    if p.name.startswith(".env") and p.name != ".env.example":
        return True
    if re.fullmatch(r"appsettings(?:\..+)?\.local\.json", p.name) or p.name == "appsettings.production.json":
        return True
    if p.suffix in {".pem", ".key", ".pfx", ".p12", ".jks", ".kdbx", ".dump", ".backup", ".bak", ".sqlite", ".sqlite3", ".log", ".suo", ".user"}:
        return True
    return name.startswith(("deploy/private/", "deployment/private/", "infra/private/",
                            "src/Yorungez.Web/generated/", "src/Yorungez.Web/public/pwa/"))


def private_values():
    values = set()
    env = ROOT / ".env"
    if env.exists():
        for line in env.read_text(encoding="utf-8-sig").splitlines():
            key, sep, value = line.partition("=")
            if sep and re.search(r"PASSWORD|SECRET|TOKEN|SIGNING_KEY|API_KEY|EMAIL__SENDER|EMAIL__USERNAME", key):
                value = value.strip().strip("\"'")
                if len(value) >= 8 and not value.lower().startswith(("replace", "example")):
                    values.add(value)
                    if "PASSWORD" in key:
                        compact = re.sub(r"\s+", "", value)
                        values.add(compact)
                        if re.fullmatch("[a-z]{16}", compact):
                            values.add(" ".join(compact[i:i + 4] for i in range(0, 16, 4)))
    return {v.encode("utf-8") for v in values if len(v) >= 8}


def main():
    patterns = {
        "private-key": rb"-----BEGIN (?:RSA |EC |OPENSSH |ENCRYPTED )?PRIVATE KEY-----",
        "github-token": rb"\b(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{35,})\b",
        "google-api-key": rb"\bAIza[0-9A-Za-z_-]{35}\b",
        "aws-access-key": rb"\b(?:AKIA|ASIA)[0-9A-Z]{16}\b",
    }
    known = private_values()
    failures = []
    count = total = 0
    for name, mode, body in indexed_blobs():
        count += 1
        total += len(body)
        if forbidden_path(name) or mode == b"120000":
            failures.append((name, "forbidden-path-or-symlink"))
        if len(body) >= 90 * 1024 * 1024:
            failures.append((name, "oversized-file"))
        if any(value in body for value in known):
            failures.append((name, "local-private-value"))
        for rule, pattern in patterns.items():
            if re.search(pattern, body):
                failures.append((name, rule))
    if failures:
        for name, rule in failures:
            print(f"BLOCKED {name}: {rule}", file=sys.stderr)
        raise SystemExit(1)
    print(json.dumps({"status": "passed", "indexedFiles": count,
                      "indexedBytes": total, "localPrivateValuesCompared": bool(known),
                      "matchedValuesPrinted": False}))


if __name__ == "__main__":
    main()
