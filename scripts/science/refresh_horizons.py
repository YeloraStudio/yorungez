"""Explicit, sequential JPL reference refresh. Tests never use the network.

Run: python scripts/science/refresh_horizons.py --refresh
Only synthetic/public example coordinates are sent. Never read user coordinates.
"""
import argparse
import csv
import hashlib
import io
import json
import time
import urllib.parse
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / "tests" / "ReferenceData" / "Horizons"
BODIES = {"sun": "10", "moon": "301", "mercury": "199", "venus": "299", "mars": "499",
          "jupiter": "599", "saturn": "699", "uranus": "799", "neptune": "899"}
POSITIONS = [
    ("istanbul-sun", "sun", 41.0082, 28.9784, 0, "2026-10-30T20:00:00Z"),
    ("istanbul-moon", "moon", 41.0082, 28.9784, 0, "2026-10-30T20:00:00Z"),
    ("istanbul-saturn", "saturn", 41.0082, 28.9784, 0, "2026-10-30T20:00:00Z"),
    ("zero-jupiter-midnight", "jupiter", 0, 0, 0, "2026-01-01T00:00:00Z"),
    ("south-moon", "moon", -33.8688, 151.2093, 0, "2026-06-21T00:00:00Z"),
    ("dateline-east-mars", "mars", 10, 180, 0, "2026-10-30T23:59:00Z"),
    ("dateline-west-mars", "mars", 10, -180, 0, "2026-10-30T23:59:00Z"),
    ("near-north-pole-neptune", "neptune", 89.9, 0, 0, "2026-03-20T12:00:00Z"),
    ("near-south-pole-venus", "venus", -89.9, 30, 0, "2026-12-21T12:00:00Z"),
    ("past-mercury", "mercury", 51.48, 0, 0, "2000-01-01T12:00:00Z"),
    ("future-uranus", "uranus", 35, -110, 0, "2035-12-31T08:00:00Z"),
    ("high-observer-moon", "moon", -23, -67, 2500, "2026-10-30T04:00:00Z"),
]
EVENTS = [
    ("equinox-sun-istanbul", "sun", 41.0082, 28.9784, 0, "2026-03-20T00:00:00Z"),
    ("moon-sydney", "moon", -33.8688, 151.2093, 0, "2026-10-30T00:00:00Z"),
    ("polar-summer-sun", "sun", 80, 0, 0, "2026-06-21T00:00:00Z"),
    ("polar-winter-sun", "sun", 80, 0, 0, "2026-12-21T00:00:00Z"),
]


def utc(value):
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def iso(value):
    return value.isoformat(timespec="milliseconds").replace("+00:00", "Z")


def parse_rows(result):
    before, data = result.split("$$SOE", 1)
    data, _ = data.split("$$EOE", 1)
    header = next(line for line in reversed(before.splitlines()) if "Azi" in line and "Elev" in line)
    columns = next(csv.reader([header]))
    az = next(i for i, name in enumerate(columns) if "Azi" in name)
    alt = next(i for i, name in enumerate(columns) if "Elev" in name)
    jd = next(i for i, name in enumerate(columns) if "JDUT" in name)
    rows = []
    for row in csv.reader(io.StringIO(data.strip())):
        if not row:
            continue
        instant = datetime(2000, 1, 1, 12, tzinfo=timezone.utc) + timedelta(days=float(row[jd]) - 2451545.0)
        rows.append({"instantUtc": iso(instant), "azimuthDegrees": float(row[az]), "altitudeDegrees": float(row[alt])})
    if not rows:
        raise ValueError("No reference ephemeris rows")
    return rows


def fetch(case, event):
    name, body, lat, lon, elevation, instant = case
    params = {"format": "json", "COMMAND": BODIES[body], "OBJ_DATA": "NO", "MAKE_EPHEM": "YES",
              "EPHEM_TYPE": "OBSERVER", "CENTER": "coord@399", "COORD_TYPE": "GEODETIC",
              "SITE_COORD": f"{lon},{lat},{elevation / 1000}", "QUANTITIES": "4",
              "APPARENT": "AIRLESS", "REF_SYSTEM": "ICRF", "TIME_TYPE": "UT", "TIME_ZONE": "+00:00",
              "CAL_TYPE": "GREGORIAN", "CAL_FORMAT": "BOTH", "TIME_DIGITS": "FRACSEC",
              "CSV_FORMAT": "YES", "EXTRA_PREC": "YES", "ANG_FORMAT": "DEG", "ELEV_CUT": "-90"}
    if event:
        params.update(START_TIME=utc(instant).strftime("%Y-%m-%d %H:%M:%S"),
                      STOP_TIME=(utc(instant) + timedelta(days=1)).strftime("%Y-%m-%d %H:%M:%S"), STEP_SIZE="5 m")
    else:
        params.update(TLIST=utc(instant).strftime("%Y-%m-%d %H:%M:%S"), TLIST_TYPE="CAL")
    url = "https://ssd.jpl.nasa.gov/api/horizons.api?" + urllib.parse.urlencode(
        {key: value if key == "format" else f"'{value}'" for key, value in params.items()})
    request = urllib.request.Request(url, headers={"User-Agent": "yorungez-science-reference/1.0"})
    with urllib.request.urlopen(request, timeout=60) as response:
        raw = response.read()
    payload = json.loads(raw)
    if payload.get("error") or "$$SOE" not in payload.get("result", ""):
        raise ValueError(f"Horizons failed for {name}: {payload.get('error', 'missing table')}")
    rows = parse_rows(payload["result"])
    record = {"id": name, "body": body, "latitude": lat, "longitude": lon, "elevationMeters": elevation,
              "instantUtc": instant, "sourceUrl": url, "retrievedAtUtc": iso(datetime.now(timezone.utc)),
              "rawSha256": hashlib.sha256(raw).hexdigest(), "signature": payload.get("signature"), "rows": rows}
    print(f"Fetched {name}: {len(rows)} rows", flush=True)
    return record, raw


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--refresh", action="store_true", help="Explicitly fetch and replace JPL reference files")
    if not parser.parse_args().refresh:
        parser.error("Pass --refresh to make network requests; normal tests use saved reference files.")
    DEST.mkdir(parents=True, exist_ok=True)
    (DEST / "raw").mkdir(exist_ok=True)
    records = {"schemaVersion": 1, "source": "NASA/JPL Horizons observer ephemeris",
               "model": "airless topocentric apparent body-center AZ/EL; geodetic east-positive longitude; height km in request",
               "positionToleranceArcminutes": 1.0, "crossingToleranceSeconds": 60.0,
               "positions": [], "events": []}
    staged_raw = {}
    # One outstanding request at a time. Never run against the service during tests/builds.
    for collection, cases, event in [("positions", POSITIONS, False), ("events", EVENTS, True)]:
        for case in cases:
            record, raw = fetch(case, event)
            records[collection].append(record)
            staged_raw[case[0]] = raw
            time.sleep(0.2)
    # A network/parse failure above leaves existing reference files unchanged.
    # Hash verification detects an interrupted multi-file filesystem write below.
    for name, raw in staged_raw.items():
        (DEST / "raw" / f"{name}.json").write_bytes(raw)
    # Publish only a complete, successfully parsed fixture set.
    temporary = DEST / "references.json.pending"
    temporary.write_text(json.dumps(records, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    temporary.replace(DEST / "references.json")


if __name__ == "__main__":
    main()
