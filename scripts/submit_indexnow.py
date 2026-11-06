"""Submit only the canonical public knowledge/sky pages; --submit is explicit."""
import argparse
import json
from pathlib import Path
import urllib.request

root = Path(__file__).resolve().parent.parent
config = json.loads((root / 'data/knowledge/indexnow.json').read_text(encoding='utf-8'))
guides = json.loads((root / 'data/knowledge/guides.json').read_text(encoding='utf-8'))['guides']
paths = ['', '/library', '/terms', '/about', '/mobile', '/privacy'] + ['/library/' + g['slug'] for g in guides]
urls = ['https://yorungez.com/' + lang + p for lang in ['en', 'tr'] for p in paths]
args = argparse.ArgumentParser(description=__doc__)
args.add_argument('--submit', action='store_true')
options = args.parse_args()
if not options.submit:
    print(json.dumps({'mode': 'dry-run', 'publicUrlCount': len(urls), 'urls': urls}, indent=2))
else:
    # The key is a public host-ownership proof, not an application credential.
    headers = {'User-Agent': 'Yorungez-IndexNow/1.0 (+https://yorungez.com/en/about)'}
    proof_request = urllib.request.Request(config['keyLocation'], headers=headers)
    with urllib.request.urlopen(proof_request, timeout=30) as response:
        if response.read().decode().strip() != config['publicOwnershipProof']:
            raise SystemExit('Live IndexNow ownership proof does not match; no URLs submitted.')
    payload = json.dumps({'host': config['host'], 'key': config['publicOwnershipProof'],
                          'keyLocation': config['keyLocation'], 'urlList': urls}).encode()
    request = urllib.request.Request('https://api.indexnow.org/indexnow', data=payload,
                                     headers={**headers, 'Content-Type': 'application/json; charset=utf-8'})
    with urllib.request.urlopen(request, timeout=30) as response:
        print(json.dumps({'status': response.status, 'publicUrlCount': len(urls),
                          'meaning': 'Submission accepted; crawling and indexing are not guaranteed.'}))
