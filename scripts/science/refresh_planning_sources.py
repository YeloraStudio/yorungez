"""Explicitly archive public USNO facts and a local GeoNames gazetteer; no user coordinates are sent."""
import argparse,datetime,gzip,hashlib,io,json,time,urllib.request,zipfile
from pathlib import Path
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--refresh',action='store_true');p.add_argument('--source',choices=['events','places'],required=True)
args=p.parse_args()
if not args.refresh:p.error('An explicit --refresh is required.')
root=Path(__file__).resolve().parents[2]
def fetch(url):
 for attempt in range(3):
  try:return urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'Yorungez scientific-reference-builder/0.1'}),timeout=45).read()
  except Exception:
   if attempt==2:raise
   time.sleep(2+attempt)
def sha(b):return hashlib.sha256(b).hexdigest()
if args.source=='events':
 out=root/'data/events/usno';out.mkdir(parents=True,exist_ok=True);sources=[]
 for year in range(2000,2036):
  file=out/f'{year}.json';url=f'https://aa.usno.navy.mil/api/moon/phases/year?year={year}'
  raw=file.read_bytes() if file.exists() else fetch(url)
  doc=json.loads(raw);assert doc.get('year',year)==year and len(doc['phasedata']) in range(48,52)
  if not file.exists():file.write_bytes(raw);time.sleep(1.1)
  sources.append(dict(year=year,url=url,sha256=sha(raw),file=f'data/events/usno/{year}.json'))
  print(f'Archived USNO {year}',flush=True)
 (out.parent/'sources.json').write_text(json.dumps(dict(retrievedAtUtc=datetime.datetime.now(datetime.timezone.utc).isoformat(),source='USNO Astronomical Applications Department',timeScale='Universal Time, published to the nearest minute; treated as UTC at minute precision',sources=sources),indent=2)+'\n',encoding='utf-8')
else:
 out=root/'data/places';out.mkdir(parents=True,exist_ok=True);cache=root/'.local/geonames';cache.mkdir(parents=True,exist_ok=True)
 urls=['https://download.geonames.org/export/dump/cities500.zip','https://download.geonames.org/export/dump/admin1CodesASCII.txt','https://download.geonames.org/export/dump/TR.zip'];raws=[]
 for url in urls:
  file=cache/url.rsplit('/',1)[1];raw=file.read_bytes() if file.exists() else fetch(url)
  file.write_bytes(raw);raws.append(raw)
 regions={x[0]:x[1] for line in raws[1].decode('utf-8').splitlines() if len(x:=line.split('\t'))>=2}
 rows=[]
 for line in zipfile.ZipFile(io.BytesIO(raws[0])).read('cities500.txt').decode('utf-8').splitlines():
  x=line.split('\t')
  rows.append(dict(id=int(x[0]),name=x[1],ascii=x[2],latitude=float(x[4]),longitude=float(x[5]),country=x[8],region=regions.get(x[8]+'.'+x[10],''),population=int(x[14]),feature=x[7]))
 existing={row['id'] for row in rows}
 for line in zipfile.ZipFile(io.BytesIO(raws[2])).read('TR.txt').decode('utf-8').splitlines():
  x=line.split('\t')
  if x[7]!='ADM2' or int(x[0]) in existing:continue
  rows.append(dict(id=int(x[0]),name=x[1],ascii=x[2],latitude=float(x[4]),longitude=float(x[5]),country=x[8],region=regions.get(x[8]+'.'+x[10],''),population=int(x[14]),feature=x[7]))
 rows.sort(key=lambda r:r['id']);data=(json.dumps(rows,ensure_ascii=False,separators=(',',':'))+'\n').encode();packed=gzip.compress(data,mtime=0);(out/'cities.json.gz').write_bytes(packed)
 (out/'manifest.json').write_text(json.dumps(dict(schemaVersion=1,retrievedAtUtc=datetime.datetime.now(datetime.timezone.utc).isoformat(),count=len(rows),sha256=sha(packed),jsonSha256=sha(data),sources=[dict(url=u,sha256=sha(r)) for u,r in zip(urls,raws)],author='GeoNames',license='CC BY 4.0',licenseUrl='https://creativecommons.org/licenses/by/4.0/',limitation='Nearest populated-place point, not an administrative polygon, street address or GPS accuracy improvement.'),indent=2)+'\n',encoding='utf-8')
 print(f'Prepared {len(rows)} GeoNames places; {len(packed)} compressed bytes.',flush=True)
