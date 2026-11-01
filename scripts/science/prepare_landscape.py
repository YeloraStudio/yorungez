"""Preserve an explicitly refreshed, licensed photographic landscape (no image alteration)."""
import argparse, hashlib, io, json, urllib.request, zipfile
from pathlib import Path
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--refresh',action='store_true')
if not p.parse_args().refresh: p.error('Use --refresh explicitly; normal builds verify local files only.')
root=Path(__file__).resolve().parents[2]
url='https://github.com/Stellarium/stellarium-data/releases/download/landscapes/stara_lesna.zip'
archive=urllib.request.urlopen(url,timeout=60).read()
z=zipfile.ZipFile(io.BytesIO(archive))
photo=z.read('stara_lesna/slnew.png')
out=root/'src/Yorungez.Web/public/landscapes';out.mkdir(parents=True,exist_ok=True)
(out/'stara-lesna.png').write_bytes(photo)
notice=root/'third-party/stara-lesna';notice.mkdir(parents=True,exist_ok=True)
for src,dest in [('readme.txt','UPSTREAM-readme.txt'),('landscape.ini','UPSTREAM-landscape.ini')]:
 (notice/dest).write_bytes(z.read('stara_lesna/'+src))
(root/'data/catalog/landscape-manifest.json').write_text(json.dumps(dict(
 sourceUrl=url,archiveSha256=hashlib.sha256(archive).hexdigest(),
 file='src/Yorungez.Web/public/landscapes/stara-lesna.png',url='/landscapes/stara-lesna.png',
 sha256=hashlib.sha256(photo).hexdigest(),bytes=len(photo),width=4096,height=2048,
 author='Ľubomír Hambálek',name='Stara Lesna Meadows',
 license='CC BY-SA 4.0 (listing); CC BY 4.0 (archive readme)',
 licenseUrl='https://creativecommons.org/licenses/by-sa/4.0/',
 sourceListing='https://stellarium.org/landscapes-europe.html',
 modifications='None. Original transparent PNG preserved; runtime projection and daylight grading only.',
 limitation='Illustrative photographed scenery in Slovakia, not user-location terrain or measured horizon.'
 ),indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
print('Preserved original photographic panorama and upstream notices; manifest hashes recorded.')
