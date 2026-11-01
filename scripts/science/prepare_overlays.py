"""Explicit upstream refresh for OpenNGC and unmodified Stellarium artwork."""
import csv
import hashlib
import json
from pathlib import Path
from urllib.request import Request, urlopen
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[2]
CACHE = ROOT / ".local/expansion"
ART_REV = "014fbb5e59233d133c22f9811af96b67d05a95c9"
NGC_REV = "be3cd6c5498806a2fbb2f7e0452ef802dbb02be0"
BASE = f"https://raw.githubusercontent.com/Stellarium/stellarium-skycultures/{ART_REV}/western/"
def fetch(url, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists():
        with urlopen(Request(url, headers={"User-Agent": "Yorungez/0.2 catalogue preparation"}), timeout=30) as response:
            path.write_bytes(response.read())
    return hashlib.sha256(path.read_bytes()).hexdigest()
def coords(raw, hours=False):
    sign = -1 if raw.startswith("-") else 1
    h, m, s = map(float, raw.lstrip("+-").split(":"))
    return sign * (h + m / 60 + s / 3600)
def main():
    import argparse
    parser = argparse.ArgumentParser(); parser.add_argument("--refresh", action="store_true")
    if not parser.parse_args().refresh: raise SystemExit("Use --refresh explicitly to download new public assets.")
    ngc_url = f"https://raw.githubusercontent.com/mattiaverga/OpenNGC/{NGC_REV}/database_files/NGC.csv"
    fetch(ngc_url, CACHE / "NGC.csv"); fetch(BASE + "index.json", CACHE / "western.json")
    dsos = []
    for row in csv.DictReader((CACHE / "NGC.csv").open(encoding="utf-8-sig"), delimiter=";"):
        if not row["M"] or not row["RA"] or not row["Dec"]: continue
        m = int(row["M"]); designation = row["Name"][:3] + " " + str(int(row["Name"][3:]))
        dsos.append({"id": "dso-" + row["Name"].lower(), "name": f"M{m}", "designation": designation,
            "aliases": [f"M {m}", f"Messier {m}", designation.replace(" ", ""), row["Name"], row["Common names"]],
            "type": row["Type"], "raHoursJ2000": coords(row["RA"], True), "decDegreesJ2000": coords(row["Dec"]),
            "magnitude": float(row["V-Mag"]) if row["V-Mag"] else None,
            "majorArcminutes": float(row["MajAx"]) if row["MajAx"] else None})
    dsos.sort(key=lambda row: int(row["name"][1:]))
    stars = {int(row["hip"]): row for row in csv.DictReader((ROOT / ".local/catalog/hygdata_v41.csv").open(encoding="utf-8")) if row["hip"]}
    figures = []; anchors = []; downloads = []
    for item in json.loads((CACHE / "western.json").read_text(encoding="utf-8"))["constellations"]:
        image = item.get("image")
        if not image: continue
        if len(image["anchors"]) != 3: raise ValueError("Expected three image anchors")
        indices = []
        for anchor in image["anchors"]:
            star = stars[anchor["hip"]]
            indices.append(len(anchors))
            anchors.append({"x": anchor["pos"][0], "y": anchor["pos"][1], "star": {
                "id": "hyg-" + star["id"], "raHoursJ2000": float(star["ra"]), "decDegreesJ2000": float(star["dec"]),
                "positionPc": [float(star[k]) for k in ("x","y","z")], "velocityPcPerYear": [float(star[k]) for k in ("vx","vy","vz")]}})
        filename = Path(image["file"]).name
        figures.append({"id": "con-" + item["iau"].lower(), "src": "/sky-art/" + filename, "size": image["size"], "anchors": indices})
        downloads.append((BASE + image["file"], ROOT / "src/Yorungez.Web/public/sky-art" / filename))
    with ThreadPoolExecutor(max_workers=4) as pool:
        hashes = list(pool.map(lambda pair: fetch(*pair), downloads))
    payload = {"schemaVersion": 1, "deepSky": dsos, "art": {"figures": figures, "anchors": anchors}}
    out = ROOT / "data/catalog/overlays.json"
    out.write_text(json.dumps(payload, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
    manifest = {"schemaVersion": 1, "generatedAtUtc": datetime.now(timezone.utc).isoformat(),
        "sha256": hashlib.sha256(out.read_bytes()).hexdigest(), "deepSkyCount": len(dsos), "artCount": len(figures),
        "sources": [{"url": ngc_url, "sha256": hashlib.sha256((CACHE/"NGC.csv").read_bytes()).hexdigest()},
                    {"url": BASE+"index.json", "sha256": hashlib.sha256((CACHE/"western.json").read_bytes()).hexdigest()}],
        "artFiles": [{"url": pair[0], "file": str(pair[1].relative_to(ROOT)).replace("\\","/"), "sha256": digest} for pair,digest in zip(downloads,hashes)],
        "attribution": {"deepSky": "OpenNGC, Mattia Verga and contributors, CC BY-SA 4.0; Messier subset, reformatted",
            "art": "Johan Meuris / Stellarium Western sky culture, Free Art License; unmodified artwork; three source star anchors projected by yorungez",
            "anchorStars": "HYG 4.1, David Nash / Astronexus, CC BY-SA 4.0"}}
    (out.parent / "overlays-manifest.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    license_path = ROOT / "third-party/openngc/LICENSE.txt"
    fetch(f"https://raw.githubusercontent.com/mattiaverga/OpenNGC/{NGC_REV}/LICENSES/CC-BY-SA-4.0.txt", license_path)
    desc = ROOT / "third-party/stellarium-art/UPSTREAM-description.md"
    fetch(BASE+"description.md", desc)
    print(f"Prepared {len(dsos)} Messier matches and {len(figures)} licensed artwork files; no runtime Stellarium engine code imported.")
if __name__ == "__main__": main()
