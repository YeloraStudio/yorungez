"""Prepare a small offline OpenNGC supplement from the already pinned input."""

import csv
import hashlib
import json
from pathlib import Path

from prepare_overlays import coords

ROOT = Path(__file__).resolve().parents[2]
CATALOGUE = ROOT / "data/catalog"
SELECTED = """
IC0010 IC0342 IC1101 IC4651 NGC0055 NGC0253 NGC0300 NGC0404 NGC0891
NGC1023 NGC1097 NGC1232 NGC1300 NGC1316 NGC1365 NGC1399 NGC1404 NGC1512
NGC1566 NGC1672 NGC1705 NGC2442 NGC2683 NGC2841 NGC2903 NGC2997 NGC3079
NGC3115 NGC3169 NGC3227 NGC3310 NGC3344 NGC3521 NGC3628 NGC4038 NGC4039
NGC4214 NGC4244 NGC4449 NGC4565 NGC4631 NGC4656 NGC4697 NGC4725 NGC4945
NGC5005 NGC5033 NGC5102 NGC5128 NGC5189 NGC5248 NGC5253 NGC5746 NGC5907
NGC6744 NGC6822 NGC6946 NGC7318A NGC7318B NGC7331 NGC7479 NGC7814
""".split()


def main():
    manifest = json.loads((CATALOGUE / "overlays-manifest.json").read_text("utf-8"))
    source = next(row for row in manifest["sources"] if row["url"].endswith("/NGC.csv"))
    path = ROOT / ".local/expansion/NGC.csv"
    if hashlib.sha256(path.read_bytes()).hexdigest() != source["sha256"]:
        raise ValueError("OpenNGC input does not match the existing pinned source")
    with path.open(encoding="utf-8-sig", newline="") as stream:
        records = {row["Name"]: row for row in csv.DictReader(stream, delimiter=";")}
    objects = []
    for identifier in sorted(SELECTED):
        row = records[identifier]
        if row["M"] or row["Type"] not in {"G", "GPair", "OCl", "PN"}:
            raise ValueError(f"Unexpected object type or duplicate Messier entry: {identifier}")
        designation = f"{identifier[:3]} {identifier[3:].lstrip('0')}"
        aliases = [identifier, *filter(None, row["Common names"].split(","))]
        objects.append({
            "id": f"dso-{identifier.lower()}",
            "name": designation,
            "designation": designation,
            "aliases": aliases,
            "type": row["Type"],
            "raHoursJ2000": coords(row["RA"]),
            "decDegreesJ2000": coords(row["Dec"]),
            "magnitude": float(row["V-Mag"]) if row["V-Mag"] else None,
            "majorArcminutes": float(row["MajAx"]) if row["MajAx"] else None,
        })
    payload = {"schemaVersion": 1, "source": source, "deepSky": objects}
    output = CATALOGUE / "mobile-deep-sky.json"
    output.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
                      encoding="utf-8", newline="\n")


if __name__ == "__main__":
    main()
