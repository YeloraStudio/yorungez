"""Explicit refresh of reviewed native archive assets. No build runs this script."""

import argparse
import hashlib
import json
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[2]
CATALOGUE = ROOT / "data/catalog"
DESTINATION = CATALOGUE / "mobile-images"
CC_BY = "https://creativecommons.org/licenses/by/4.0/"
NASA_MEDIA = "https://www.nasa.gov/nasa-brand-center/images-and-media/"
USER_AGENT = "Yorungez/1.0 contact info@yorungez.com"


def asset(filename, source, download, credit, rights=CC_BY, captions=None):
    return {
        "file": f"data/catalog/mobile-images/{filename}.jpg",
        "sourceUrl": source,
        "originalUrl": download,
        "credit": credit,
        "license": "CC BY 4.0" if rights == CC_BY else "NASA media usage guidelines",
        "licenseUrl": rights,
        **({"captions": captions} if captions else {}),
    }


def eso(filename, asset_id, credit, captions=None):
    return asset(filename, f"https://www.eso.org/public/images/{asset_id}/",
                 f"https://cdn.eso.org/images/screen/{asset_id}.jpg",
                 credit, captions=captions)


def hubble(filename, asset_id, credit, captions=None):
    return asset(filename, f"https://esahubble.org/images/{asset_id}/",
                 f"https://cdn.esahubble.org/archives/images/screen/{asset_id}.jpg",
                 credit, captions=captions)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--refresh", action="store_true")
    if not parser.parse_args().refresh:
        raise SystemExit("Use --refresh explicitly.")
    triangle = hubble("summer-triangle", "heic0720c", "A. Fujii")
    ara = eso("ic4651", "eso1534a", "ESO")
    antennae = hubble(
        "antennae", "heic0615a",
        "NASA, ESA, and the Hubble Heritage Team (STScI/AURA)-ESA/Hubble Collaboration. "
        "Acknowledgement: B. Whitmore (Space Telescope Science Institute) and James Long (ESA/Hubble).",
        {"en": "Both interacting galaxies, NGC 4038 and NGC 4039.",
         "tr": "Etkileşen iki gökada birlikte, NGC 4038 ve NGC 4039."},
    )
    images = {
        "sat-25544": asset(
            "iss", "https://images.nasa.gov/details/iss073e0008524",
            "https://images-assets.nasa.gov/image/iss073e0008524/iss073e0008524~small.jpg",
            "NASA/Nichole Ayers", NASA_MEDIA,
            {"en": "Forward section of the ISS, photographed on 1 May 2025.",
             "tr": "1 Mayıs 2025’te fotoğraflanan ISS’nin ön bölümü."},
        ),
        "hyg-90979": {**triangle, "captions": {
            "en": "Summer Triangle star field. Vega is at the upper left.",
            "tr": "Yaz Üçgeni yıldız alanı. Vega sol üstte.",
        }},
        "hyg-97338": {**triangle, "captions": {
            "en": "Summer Triangle star field. Altair is near the lower middle.",
            "tr": "Yaz Üçgeni yıldız alanı. Altair alt orta bölgede.",
        }},
        "hyg-101767": {**triangle, "captions": {
            "en": "Summer Triangle star field. Deneb is at the far left.",
            "tr": "Yaz Üçgeni yıldız alanı. Deneb en solda.",
        }},
        "con-ara": {**ara, "captions": {
            "en": "IC 4651, a star cluster within Ara.",
            "tr": "Sunak takımyıldızı içindeki IC 4651 yıldız kümesi.",
        }},
        "dso-ic4651": ara,
        "dso-ngc0253": eso(
            "sculptor", "eso1025a",
            "ESO/J. Emerson/VISTA. Acknowledgment: Cambridge Astronomical Survey Unit",
            {"en": "Infrared image from VISTA.", "tr": "VISTA kızılötesi görüntüsü."},
        ),
        "dso-ngc0300": eso("ngc0300", "eso1037a", "ESO"),
        "dso-ngc1097": eso("ngc1097", "eso0128a", "ESO"),
        "dso-ngc1232": eso("ngc1232", "eso1042g", "ESO/P. Grosbøl"),
        "dso-ngc1300": eso("ngc1300", "eso2110f", "ESO/PHANGS"),
        "dso-ngc1365": eso("ngc1365", "eso9920f", "ESO"),
        "dso-ngc4038": antennae,
        "dso-ngc4039": antennae,
        "dso-ngc4594": eso("sombrero", "eso0007a", "ESO/P. Barthel",
                          {"en": "Acknowledgments: Mark Neeser (Kapteyn Institute, Groningen) and Richard Hook (ST/ECF, Garching, Germany).",
                           "tr": "Katkıda bulunanlar: Mark Neeser (Kapteyn Institute, Groningen) ve Richard Hook (ST/ECF, Garching, Germany)."}),
        "dso-ngc5128": eso("centaurus-a", "eso1221a", "ESO"),
        "dso-ngc5194": hubble(
            "whirlpool", "heic0506a",
            "NASA, ESA, S. Beckwith (STScI), and The Hubble Heritage Team (STScI/AURA)",
        ),
    }

    def download(entry):
        request = Request(entry["originalUrl"], headers={"User-Agent": USER_AGENT})
        with urlopen(request, timeout=25) as response:
            data = response.read(1_000_001)
        if len(data) > 1_000_000 or not data.startswith(b"\xff\xd8\xff"):
            raise ValueError(f"Expected a bounded JPEG preview: {entry['file']}")
        return entry["file"], data

    unique = {entry["file"]: entry for entry in images.values()}
    with ThreadPoolExecutor(max_workers=4) as executor:
        files = dict(executor.map(download, unique.values()))
    DESTINATION.mkdir(parents=True, exist_ok=True)
    for name, data in files.items():
        (ROOT / name).write_bytes(data)
    for entry in images.values():
        data = files[entry["file"]]
        entry.update(sha256=hashlib.sha256(data).hexdigest(), bytes=len(data))
    (CATALOGUE / "mobile-object-media.json").write_text(
        json.dumps({"schemaVersion": 1, "images": images}, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8", newline="\n",
    )


if __name__ == "__main__":
    main()
