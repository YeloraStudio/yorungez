"""Explicitly refresh attributed Commons photographs; never runs during normal build/test."""
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.parse import urlencode, urlparse
from datetime import datetime, timezone
import argparse, hashlib, html, json, re

ROOT = Path(__file__).resolve().parents[2]
FILES = {
    "moon": "FullMoon2010.jpg",
    "mercury": "Mercury in true color.jpg",
    "venus": "Venus-real color.jpg",
    "mars": "OSIRIS Mars true color.jpg",
    "jupiter": "Jupiter and its shrunken Great Red Spot.jpg",
    "saturn": "Saturn during Equinox.jpg",
    "uranus": "Uranus2.jpg",
    "neptune": "Neptune Full.jpg",
    "hyg-32263": "Sirius A and B Hubble photo.jpg",
    "dso-ngc0224": "M31-Andromede-16-09-2023-Hamois.jpg",
    "dso-ngc1976": "Orion Nebula - Hubble 2006 mosaic 18000.jpg",
}

def get(url):
    with urlopen(Request(url, headers={"User-Agent": "Yorungez/0.3 (attributed astronomy card photographs)"}), timeout=25) as response:
        data = response.read(3_000_001)
        if len(data) > 3_000_000:
            raise ValueError("Photograph exceeds the preparation budget")
        return data

def plain(value):
    return html.unescape(re.sub(r"<[^>]*>", "", value or "")).strip()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--refresh", action="store_true")
    if not parser.parse_args().refresh:
        raise SystemExit("Use --refresh explicitly.")
    query = dict(action="query", prop="imageinfo", iiprop="url|extmetadata|timestamp|sha1", iiurlwidth=640,
                 titles="|".join("File:" + name for name in FILES.values()), format="json", formatversion=2)
    pages = json.loads(get("https://commons.wikimedia.org/w/api.php?" + urlencode(query)))["query"]["pages"]
    by_title = {page["title"]: page for page in pages}
    previous_path = ROOT / 'data/catalog/object-media.json'
    previous_images = json.loads(previous_path.read_text(encoding='utf-8'))['images'] if previous_path.exists() else {}
    output = {}
    for object_id, name in FILES.items():
        page = by_title["File:" + name]
        info = page["imageinfo"][0]
        metadata = info["extmetadata"]
        value = lambda key: plain(metadata.get(key, {}).get("value", ""))
        source = info["descriptionurl"]
        license_name, license_url, credit = value("LicenseShortName"), value("LicenseUrl"), value("Artist")
        if not license_url and license_name == "Public domain" and value("Copyrighted").lower() == "false":
            license_url = source + "#Licensing"
        if not credit or not license_url.startswith("https://") or not license_name:
            raise ValueError("Missing explicit photograph attribution: " + object_id)
        remote = info.get("thumburl", info["url"])
        if urlparse(remote).hostname not in {"upload.wikimedia.org", "thumb.wikimedia.org"}:
            raise ValueError("Unexpected photograph host")
        data = b''
        # Reuse only byte-identical, previously verified downloads of this same source version.
        path = ROOT / f"src/Yorungez.Web/public/objects/{object_id}.jpg"
        previous = previous_images.get(object_id)
        if previous and previous.get('sourceSha1') == info['sha1'] and path.exists():
            candidate = path.read_bytes()
            if hashlib.sha256(candidate).hexdigest() == previous['sha256']:
                data = candidate
        if not data:
            data = get(remote)
        if not data.startswith(b"\xff\xd8\xff"):
            raise ValueError("Expected an unaltered JPEG photograph")
        path.write_bytes(data)
        declared_license = license_name
        if object_id == 'hyg-32263':
            # The file page's structured data also declares CC BY 3.0; retain that attribution obligation.
            license_name, license_url = 'CC BY 3.0', 'https://creativecommons.org/licenses/by/3.0/'
        output[object_id] = dict(url=f"/objects/{object_id}.jpg", sourceUrl=source, originalUrl=remote,
                                credit=credit, license=license_name, licenseUrl=license_url,
                                sha256=hashlib.sha256(data).hexdigest(), bytes=len(data),
                                sourceTimestamp=info["timestamp"], sourceSha1=info["sha1"],
                                copyrightDeclaration=value("Copyrighted"),
                                metadataLicense=declared_license,
                                description=value("ImageDescription"), sourceDateText=value("DateTimeOriginal"))
    manifest = dict(schemaVersion=1, fetchedAtUtc=datetime.now(timezone.utc).isoformat(),
                    note="Unaltered source JPEG previews. Archival/processed images do not represent the selected simulation instant or naked-eye appearance.", images=output)
    (ROOT / "data/catalog/object-media.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    print(json.dumps({"images": len(output), "bytes": sum(row["bytes"] for row in output.values())}))

if __name__ == "__main__":
    main()
