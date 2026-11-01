"""Explicit independent USNO standard Sun/Moon rise/set references at public test sites."""
import argparse,datetime,hashlib,json,time,urllib.parse,urllib.request
from pathlib import Path
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--refresh',action='store_true')
if not p.parse_args().refresh:p.error('Explicit --refresh required.')
root=Path(__file__).resolve().parents[2];out=root/'tests/ReferenceData/Observing';out.mkdir(parents=True,exist_ok=True);rows=[]
for name,lat,lon,date in [('balikesir',39.6484,27.8826,'2026-10-31'),('balikesir-next',39.6484,27.8826,'2026-11-01'),('sydney',-33.8688,151.2093,'2026-06-21'),('greenwich',51.4769,0,'2026-10-25'),('kathmandu',27.7172,85.324,'2026-10-31'),('arctic',78.2232,15.6469,'2026-06-21')]:
 url='https://aa.usno.navy.mil/api/rstt/oneday?'+urllib.parse.urlencode(dict(date=date,coords=f'{lat},{lon}',tz=0,dst='false'))
 raw=urllib.request.urlopen(url,timeout=45).read();doc=json.loads(raw);file=out/f'{name}.json';file.write_bytes(raw)
 rows.append(dict(site=name,latitude=lat,longitude=lon,date=date,url=url,sha256=hashlib.sha256(raw).hexdigest(),file=file.name))
 print('Archived observing reference '+name,flush=True);time.sleep(1.1)
(out/'manifest.json').write_text(json.dumps(dict(source='USNO rstt API, UT at minute precision treated as UTC',retrievedAtUtc=datetime.datetime.now(datetime.timezone.utc).isoformat(),toleranceSeconds=180,rows=rows),indent=2)+'\n',encoding='utf-8')
