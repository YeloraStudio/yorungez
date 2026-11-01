"""Derive local bright-star/constellation data from explicitly pinned upstreams.

--download is the only network path. No user coordinates are read or sent.
"""
import argparse
import csv
import hashlib
import json
import math
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CACHE = ROOT / ".local/catalog"
HYG_COMMIT = "c7f7f883fe678cc7680169a50ccd7dcc49b060ce"
D3_COMMIT = "7e720a3de062059d4c5400a379146a601d9010e0"
SOURCES = {
    "hygdata_v41.csv": f"https://raw.githubusercontent.com/astronexus/HYG-Database/{HYG_COMMIT}/hyg/CURRENT/hygdata_v41.csv",
    "constellation-lines.json": f"https://raw.githubusercontent.com/ofrohn/d3-celestial/{D3_COMMIT}/data/constellations.lines.json",
    "constellation-names.json": f"https://raw.githubusercontent.com/ofrohn/d3-celestial/{D3_COMMIT}/data/constellations.json",
}
HYG_SHA256 = "d9f69fd86bbf90a4e4d52b4c5c53eacfa6dfc0bfdef85bfd94f095e0bebe4ebd"


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def vector(ra, dec):
    r, d = math.radians(ra), math.radians(dec)
    return (math.cos(d) * math.cos(r), math.cos(d) * math.sin(r), math.sin(d))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--download", action="store_true")
    args = parser.parse_args()
    CACHE.mkdir(parents=True, exist_ok=True)
    if args.download:
        for filename, url in SOURCES.items():
            with urllib.request.urlopen(url, timeout=90) as source:
                data = source.read()
            (CACHE / filename).write_bytes(data)
    if digest(CACHE / "hygdata_v41.csv") != HYG_SHA256:
        raise ValueError("Unexpected HYG source hash")
    with (CACHE / "hygdata_v41.csv").open(encoding="utf-8", newline="") as stream:
        all_stars = [s for s in csv.DictReader(stream) if s["id"] != "0"]
    stars = {s["id"]: s for s in all_stars if s["mag"] and float(s["mag"]) <= 6}
    lines = json.loads((CACHE / "constellation-lines.json").read_text(encoding="utf-8"))
    names = {c["id"]: c for c in json.loads((CACHE / "constellation-names.json").read_text(encoding="utf-8"))["features"]}
    # Index catalogue positions by rounded 0.01-degree cells. Imported line nodes
    # are rounded J2000 points, then explicitly resolved to real catalogue IDs.
    cells = {}
    for s in all_stars:
        ra, dec = float(s["ra"]) * 15, float(s["dec"])
        cells.setdefault((round(ra * 100) % 36000, round(dec * 100)), []).append(s)
    matches = []
    def resolve(point):
        ra, dec = point[0] % 360, point[1]
        cell = (round(ra * 100) % 36000, round(dec * 100))
        candidates = []
        for dx in range(-2, 3):
            for dy in range(-2, 3):
                candidates.extend(cells.get(((cell[0] + dx) % 36000, cell[1] + dy), []))
        v = vector(ra, dec)
        def separation(s):
            other = vector(float(s["ra"]) * 15, float(s["dec"]))
            return math.degrees(math.acos(max(-1, min(1, sum(a*b for a,b in zip(v, other)))))) * 3600
        if not candidates:
            raise ValueError(f"Unresolved constellation point {point}")
        star = min(candidates, key=lambda s: (separation(s), float(s["mag"] or 100), int(s["id"])))
        distance = separation(star)
        if distance > 30:
            raise ValueError(f"Unresolved constellation node {point}: {distance} arcsec")
        stars[star["id"]] = star
        matches.append({"point": point, "starId": "hyg-" + star["id"], "separationArcseconds": distance})
        return "hyg-" + star["id"]
    patterns = []
    for c in lines["features"]:
        properties = names[c["id"]]["properties"]
        if not properties.get("tr") or not properties.get("en"):
            raise ValueError("Missing bilingual constellation name: " + c["id"])
        patterns.append({"id": "con-" + c["id"].lower(), "iau": c["id"],
                         "names": {"tr": properties["tr"], "en": properties["en"]},
                         "lines": [[resolve(point) for point in line] for line in c["geometry"]["coordinates"]]})
    # Serpens has two disconnected figures, but one IAU constellation identity.
    serpens = [p for p in patterns if p["iau"].startswith("Ser")]
    if len(serpens) == 2:
        patterns = [p for p in patterns if not p["iau"].startswith("Ser")]
        patterns.append({"id": "con-ser", "iau": "Ser", "names": {"tr": "Yılan", "en": "Serpens"},
                         "lines": [line for p in serpens for line in p["lines"]]})
    if len(patterns) != 88:
        raise ValueError("Expected 88 unique IAU constellation identities")
    records = []
    for s in sorted(stars.values(), key=lambda s: (float(s["mag"]), int(s["id"]))):
        known_distance = float(s["dist"]) < 100000
        record = {"id": "hyg-" + s["id"], "hip": int(s["hip"]) if s["hip"] else None,
                  "name": s["proper"] or ("HIP " + s["hip"] if s["hip"] else "HYG " + s["id"]),
                  "designation": s["bf"].strip(), "constellation": s["con"],
                  "raHoursJ2000": float(s["ra"]), "decDegreesJ2000": float(s["dec"]),
                  "magnitude": float(s["mag"]), "colorIndex": float(s["ci"]) if s["ci"] else None,
                  "distanceParsecs": float(s["dist"]) if known_distance else None,
                  "positionPc": [float(s[k]) for k in ("x", "y", "z")],
                  "velocityPcPerYear": [float(s[k]) for k in ("vx", "vy", "vz")],
                  "pmRaMasPerYear": float(s["pmra"]), "pmDecMasPerYear": float(s["pmdec"]),
                  "radialVelocityKmPerSecond": float(s["rv"]) if s["rv"] else None,
                  "inclusion": "bright" if float(s["mag"]) <= 6 else "constellation-node"}
        if record["distanceParsecs"] == 0:
            raise ValueError("Invalid star distance")
        records.append(record)
    output = ROOT / "data/catalog"
    output.mkdir(parents=True, exist_ok=True)
    payload = {"schemaVersion": 1, "version": "hyg-4.1-d3-2022.1", "epoch": "J2000.0",
               "stars": records, "constellations": patterns}
    raw = (json.dumps(payload, ensure_ascii=False, separators=(",", ":")) + "\n").encode()
    (output / "bright-sky.json").write_bytes(raw)
    manifest = {"schemaVersion": 1, "version": payload["version"], "generatedAtUtc": datetime.now(timezone.utc).isoformat(),
                "sources": [{"url": url, "sha256": digest(CACHE / filename)} for filename, url in SOURCES.items()],
                "derivedSha256": hashlib.sha256(raw).hexdigest(), "bytes": len(raw), "starCount": len(records),
                "brightCount": sum(s["inclusion"] == "bright" for s in records), "constellationCount": len(patterns),
                "nodeMatchMaxArcseconds": max(m["separationArcseconds"] for m in matches),
                "nodeMatches": matches,
                "attribution": {"stars": "HYG Database v4.1, David Nash / Astronexus, CC BY-SA 4.0; filtered and reformatted by yorungez",
                                "constellations": "d3-celestial, Olaf Frohn, BSD-3-Clause; IAU/Wikipedia sources credited upstream; lines resolved to HYG IDs"},
                "limitations": ["Magnitude cut is catalogue brightness, not a visibility guarantee.",
                                "HYG common labels may include unofficial secondary-star names.",
                                "Constellation figures are schematic conventions, not IAU boundary polygons.",
                                "Unknown distance is null, never the HYG 100000 parsec sentinel."]}
    (output / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Prepared {len(records)} stars ({manifest['brightCount']} bright), {len(patterns)} constellations; max node match {manifest['nodeMatchMaxArcseconds']:.3f} arcsec")


if __name__ == "__main__":
    main()
