"""Validate offline probe outputs. --publish records this machine's compact report."""
import argparse
import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--publish", action="store_true")
args = parser.parse_args()
cs = json.loads((root / ".local/science/csharp-report.json").read_text(encoding="utf-8"))
js = json.loads((root / ".local/science/javascript-report.json").read_text(encoding="utf-8"))
refs = (root / "tests/ReferenceData/Horizons/references.json").read_bytes()
data = json.loads(refs)
if any(s["azimuthPublished"] and not s["directionalTargetMet"] for s in cs["samples"]):
    raise SystemExit("Published azimuth failed reference target")
if cs["summary"]["maxAltitudeErrorArcminutes"] > 1 or not cs["summary"]["eventWindowStatusesMatch"]:
    raise SystemExit("Altitude or crossing status failed")
if cs["summary"]["maxCrossingErrorSeconds"] > 60:
    raise SystemExit("Crossing time failed")
if (js["summary"]["maxAzimuthDeltaDegrees"] > 1e-7 or js["summary"]["maxAltitudeDeltaDegrees"] > 1e-7
        or js["summary"]["maxCrossingDeltaSeconds"] > 0.01 or not js["summary"]["crossingStatusesMatch"]):
    raise SystemExit("Cross-language parity failed")
report = {
    "schemaVersion": 1, "generatedAtUtc": cs["generatedAtUtc"], "engine": cs["engine"], "version": cs["version"],
    "upstreamCommit": "61dc07020aaa6885d2c7f688a4d82beaf6edb9ef", "license": "MIT",
    "referenceSha256": hashlib.sha256(refs).hexdigest(), "referenceSource": data["source"],
    "decision": "initial scoped adapter; polar azimuth withheld; rendering and broader validation remain open",
    "tolerances": cs["tolerances"], "summary": cs["summary"],
    "originalTargetExceptions": [s for s in cs["samples"] if not s["directionalTargetMet"]],
    "positionCases": [s for s in cs["samples"] if s["id"] in {c["id"] for c in data["positions"]}],
    "crossingCases": cs["events"], "crossLanguage": js["summary"],
    "desktopCSharp": {"environment": cs["environment"], "benchmark": cs["benchmark"]},
    "desktopJavaScript": {"environment": js["environment"], "benchmark": js["benchmark"]},
    "browserAsset": js["browserAsset"],
    "limitations": ["Samples do not establish uniform accuracy across dates or sites.",
                    "Polar directional failures are retained, not accepted by a relaxed tolerance.",
                    "Five-minute JPL series roots are interpolated references, not exact event solutions.",
                    "Standard refraction is not independently validated against measured weather.",
                    "No mobile/browser rendering, accessibility, production load or offline PWA test yet."]
}
target = root / ("docs/science/astronomy-engine-2.1.19-report.json" if args.publish else ".local/science/report.json")
target.parent.mkdir(parents=True, exist_ok=True)
target.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"PASS: report gates; {cs['summary']['originalDirectionalTargetFailures']} original target exceptions retained; "
      + ("published report" if args.publish else "local report only"))
