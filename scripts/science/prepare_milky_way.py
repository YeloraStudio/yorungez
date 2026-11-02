"""Explicitly refresh only the ESO supplied screensize preview; normal builds remain offline."""
from pathlib import Path
from urllib.request import Request, urlopen
from datetime import datetime, timezone
import argparse, hashlib, json

ROOT = Path(__file__).resolve().parents[2]

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--refresh', action='store_true')
    if not parser.parse_args().refresh:
        raise SystemExit('Use --refresh explicitly; review the source file and rights notice before refreshing.')
    source = ROOT / 'data/catalog/sky-features.json'
    data = json.loads(source.read_text(encoding='utf-8'))
    photo = data['milkyWay']['image']
    if photo['originalUrl'] != 'https://cdn.eso.org/images/screen/eso0932a.jpg':
        raise ValueError('Unexpected photo source; review its provenance first')
    with urlopen(Request(photo['originalUrl'], headers={'User-Agent': 'Yorungez/0.3 (attributed sky feature)'}), timeout=25) as response:
        content = response.read(1_000_001)
    if len(content) > 1_000_000 or not content.startswith(b'\xff\xd8\xff'):
        raise ValueError('Expected a bounded JPEG preview')
    (ROOT / 'src/Yorungez.Web/public/objects/milky-way.jpg').write_bytes(content)
    photo.update(sha256=hashlib.sha256(content).hexdigest(), bytes=len(content), fetchedAtUtc=datetime.now(timezone.utc).isoformat())
    source.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')
    print(json.dumps({'images': 1, 'bytes': len(content)}))

if __name__ == '__main__':
    main()
