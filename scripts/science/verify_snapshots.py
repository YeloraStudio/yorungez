"""Verify hashes and normalized values against all saved raw responses; no network."""
import hashlib
import json
from pathlib import Path
from refresh_horizons import parse_rows

root = Path(__file__).resolve().parents[2]
folder = root / "tests/ReferenceData/Horizons"
data = json.loads((folder / "references.json").read_text(encoding="utf-8"))
count = 0
for case in data["positions"] + data["events"]:
    raw = (folder / "raw" / (case["id"] + ".json")).read_bytes()
    if hashlib.sha256(raw).hexdigest() != case["rawSha256"]:
        raise SystemExit("Raw reference hash mismatch: " + case["id"])
    source = json.loads(raw)
    if source["signature"] != case["signature"] or parse_rows(source["result"]) != case["rows"]:
        raise SystemExit("Normalized data differs from raw response: " + case["id"])
    count += len(case["rows"])
print(f"PASS: {count} normalized rows exactly match saved raw JPL responses and hashes; no network used.")
