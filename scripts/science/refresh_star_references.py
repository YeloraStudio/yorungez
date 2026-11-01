"""Explicit Astropy/ERFA reference generation; uses bundled, pinned IERS data.

Run with .local/science-venv/Scripts/python.exe. No coordinate network calls.
"""
import hashlib
import json
import warnings
from datetime import datetime, timezone
from pathlib import Path
import astropy
import astropy.units as u
from astropy.coordinates import SkyCoord, EarthLocation, AltAz
from astropy.time import Time
from astropy.utils import iers

ROOT = Path(__file__).resolve().parents[2]
iers.conf.auto_download = False
iers.conf.auto_max_age = None
iers.conf.iers_degraded_accuracy = "warn"
raw = (ROOT / "data/catalog/bright-sky.json").read_bytes()
catalog = json.loads(raw)
hips = [32349, 71683, 69673, 91262, 24608, 24436, 27989, 11767, 113368, 37279, 65474, 80763]
stars = {s["hip"]: s for s in catalog["stars"] if s["hip"] in hips}
if len(stars) != len(hips):
    raise ValueError("Missing reference star")
contexts = [
    {"id": "istanbul", "latitude": 41.0082, "longitude": 28.9784, "elevationMeters": 0},
    {"id": "sydney", "latitude": -33.8688, "longitude": 151.2093, "elevationMeters": 0},
    {"id": "zero", "latitude": 0, "longitude": 0, "elevationMeters": 0},
    {"id": "high-north", "latitude": 80, "longitude": -20, "elevationMeters": 2500},
]
instants = ["2000-01-01T12:00:00Z", "2026-10-30T20:00:00Z", "2035-12-31T08:00:00Z"]
rows, warning_messages = [], set()
for context in contexts:
    location = EarthLocation.from_geodetic(context["longitude"] * u.deg, context["latitude"] * u.deg, context["elevationMeters"] * u.m)
    for instant in instants:
        with warnings.catch_warnings(record=True) as caught:
            warnings.simplefilter("always")
            target_time = Time(instant, scale="utc")
            for hip, s in stars.items():
                coord = SkyCoord(ra=s["raHoursJ2000"] * u.hourangle, dec=s["decDegreesJ2000"] * u.deg,
                                 distance=s["distanceParsecs"] * u.pc,
                                 pm_ra_cosdec=s["pmRaMasPerYear"] * u.mas / u.yr,
                                 pm_dec=s["pmDecMasPerYear"] * u.mas / u.yr,
                                 radial_velocity=(s["radialVelocityKmPerSecond"] or 0) * u.km / u.s,
                                 obstime=Time("J2000", scale="tt"), frame="icrs")
                moved = coord.apply_space_motion(new_obstime=target_time)
                horizontal = moved.transform_to(AltAz(obstime=target_time, location=location, pressure=0 * u.hPa))
                rows.append({"starId": s["id"], "hip": hip, "context": {**context, "instantUtc": instant},
                             "azimuthDegrees": horizontal.az.deg, "altitudeDegrees": horizontal.alt.deg})
            for w in caught:
                warning_messages.add(type(w.message).__name__ + ": " + str(w.message))
result = {"schemaVersion": 1, "source": "Astropy/ERFA ICRS space motion to airless topocentric AltAz",
          "astropyVersion": astropy.__version__, "generatedAtUtc": datetime.now(timezone.utc).isoformat(),
          "catalogSha256": hashlib.sha256(raw).hexdigest(), "positionToleranceArcminutes": 1,
          "iersAutoDownload": False, "warnings": sorted(warning_messages), "rows": rows}
folder = ROOT / "tests/ReferenceData/Stars"
folder.mkdir(parents=True, exist_ok=True)
(folder / "astropy.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"Saved {len(rows)} Astropy samples; {len(warning_messages)} distinct reference warnings retained.")
