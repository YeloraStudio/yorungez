"""Build/test the same C ABI against frozen repository references. No downloads.

Run from any directory with Python and GCC on PATH. A host binary is produced
under ignored .local/mobile-science; Android/iOS builds use the same C sources.
This is numerical port evidence, not physical device or camera acceptance.
"""
import ctypes as c
import hashlib
import json
import math
from datetime import datetime
from pathlib import Path
import os
import subprocess

ROOT = Path(__file__).resolve().parents[3]
APP = ROOT / "src/Yorungez.Mobile"


def read(path):
    return json.loads((ROOT / path).read_text(encoding="utf-8-sig"))


def utc(value):
    return datetime.fromisoformat(value.replace("Z", "+00:00")).timestamp()


def separation(a, b):
    az, alt = map(math.radians, a)
    bz, blt = map(math.radians, b)
    v = math.sin(alt)*math.sin(blt)+math.cos(alt)*math.cos(blt)*math.cos(az-bz)
    return math.degrees(math.acos(max(-1, min(1, v))))*60


def main():
    upstream = ROOT / "third-party/astronomy-engine/source/c"
    manifest = json.loads((upstream / "manifest.json").read_text())
    for name, record in manifest["files"].items():
        assert hashlib.sha256((upstream / name).read_bytes()).hexdigest() == record["sha256"]
    output = ROOT / ".local/mobile-science"
    output.mkdir(parents=True, exist_ok=True)
    library = output / ("yorungez_sky.dll" if os.name == "nt" else "libyorungez_sky.so")
    subprocess.run(["gcc", "-shared", "-O2", "-fPIC", "-static-libgcc",
                    str(APP / "native/yorungez_sky.c"), str(upstream / "astronomy.c"),
                    "-o", str(library), "-lm"], check=True)
    lib = c.CDLL(str(library))
    assert lib.yg_abi_version() == 2
    lib.yg_sky.argtypes = [c.c_double]*4 + [c.POINTER(c.c_double), c.c_int]*2 + [c.POINTER(c.c_double), c.c_int]
    lib.yg_sky.restype = c.c_int

    def calculate(context, stars=(), dsos=()):
        s = (c.c_double * len(stars))(*stars)
        d = (c.c_double * len(dsos))(*dsos)
        out = (c.c_double * (81 + len(stars)//3 + len(dsos)))()
        status = lib.yg_sky(utc(context["instantUtc"]), context["latitude"], context["longitude"],
                            context.get("elevationMeters") or 0, s, len(stars)//6,
                            d, len(dsos)//2, out, len(out))
        assert status == 0, status
        return list(out)

    bodies = ["sun", "moon", "mercury", "venus", "mars", "jupiter", "saturn", "uranus", "neptune"]
    residuals = {"solar": [], "stars": [], "deepSky": []}
    js_output = subprocess.check_output(["node", str(ROOT / "tools/science-js/mobile-native-parity.mjs")])
    js = {(row["id"], row["instantUtc"]): row for row in json.loads(js_output)}
    parity = []
    skipped = []
    horizons = read("tests/ReferenceData/Horizons/references.json")
    for case in horizons["positions"] + horizons["events"]:
        if abs(case["latitude"]) >= 89:
            skipped.append(case["id"])
            continue
        for row in case["rows"]:
            context = {**case, "instantUtc": row["instantUtc"]}
            out = calculate(context)
            i = 8 * bodies.index(case["body"])
            residuals["solar"].append(separation(out[i:i+2], [row["azimuthDegrees"], row["altitudeDegrees"]]))
            other = js[(case["id"], row["instantUtc"])]
            parity.append(max(abs((out[i]-other["azimuth"]+180)%360-180), abs(out[i+1]-other["altitude"])))
    stars = {x["id"]: x for x in read("data/catalog/bright-sky.json")["stars"]}
    for row in read("tests/ReferenceData/Stars/astropy.json")["rows"]:
        star = stars[row["starId"]]
        out = calculate(row["context"], star["positionPc"] + star["velocityPcPerYear"])
        residuals["stars"].append(separation(out[72:74], [row["azimuthDegrees"], row["altitudeDegrees"]]))
    dsos = {x["id"]: x for x in read("data/catalog/overlays.json")["deepSky"]}
    for row in read("tests/ReferenceData/DeepSky/astropy.json")["rows"]:
        obj = dsos[row["id"]]
        out = calculate(row["context"], dsos=[obj["raHoursJ2000"], obj["decDegreesJ2000"]])
        residuals["deepSky"].append(separation(out[72:74], [row["azimuthDegrees"], row["altitudeDegrees"]]))
    results = {k: {"comparisons": len(v), "maxArcminutes": max(v)} for k, v in residuals.items()}
    assert all(v["maxArcminutes"] <= 1 for v in results.values()), results
    assert max(parity) <= 1e-7
    context = {"instantUtc": "2026-11-04T00:00:00Z", "latitude": 41, "longitude": 29}
    raw = (c.c_double * 81)()
    invalid = [lib.yg_sky(utc(context["instantUtc"]), 89, 29, 0, None, 0, None, 0, raw, 81),
               lib.yg_sky(float("nan"), 41, 29, 0, None, 0, None, 0, raw, 81),
               lib.yg_sky(utc("2036-01-01T00:00:00Z"), 41, 29, 0, None, 0, None, 0, raw, 81),
               lib.yg_sky(utc(context["instantUtc"]), 41, 29, 0, None, 0, None, 0, raw, 80)]
    assert invalid == [1]*4
    report = {"status": "passed", "engine": "2.1.19", "abi": 2,
              "results": results, "javascriptParity": {"comparisons": len(parity), "maxCoordinateDegrees": max(parity), "toleranceDegrees": 1e-7},
              "excludedPolarCases": skipped, "invalidInputsRejected": len(invalid)}
    (output / "report.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report))


if __name__ == "__main__":
    main()
