"""Explicit offline Astropy/ERFA reference generation for the new DSO path."""
from pathlib import Path
import hashlib,json,warnings
import argparse
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--refresh", action="store_true", help="Explicitly regenerate frozen offline references.")
if not parser.parse_args().refresh:
 parser.error("Reference generation requires explicit --refresh; normal tests only read the frozen file.")
import astropy,astropy.units as u
from astropy.coordinates import SkyCoord,EarthLocation,AltAz
from astropy.time import Time
from astropy.utils import iers
ROOT=Path(__file__).resolve().parents[2]
iers.conf.auto_download=False;iers.conf.auto_max_age=None
raw=(ROOT/'data/catalog/overlays.json').read_bytes();catalog=json.loads(raw)
rows=[];notes=set()
for site,lat,lon in [('balikesir',39.6484,27.8826),('istanbul',41.0082,28.9784),('sydney',-33.8688,151.2093),('zero',0,0)]:
 for instant in ['2000-01-01T12:00:00Z','2026-10-31T11:24:00Z','2035-06-21T00:00:00Z']:
  for name in ['M1','M13','M31','M42','M57','M104']:
   row=next(x for x in catalog['deepSky'] if x['name']==name)
   with warnings.catch_warnings(record=True) as seen:
    warnings.simplefilter('always')
    time=Time(instant,scale='utc');observer=EarthLocation.from_geodetic(lon*u.deg,lat*u.deg,0*u.m)
    pos=SkyCoord(ra=row['raHoursJ2000']*u.hourangle,dec=row['decDegreesJ2000']*u.deg,frame='icrs').transform_to(AltAz(obstime=time,location=observer,pressure=0*u.hPa))
    notes.update(type(w.message).__name__+': '+str(w.message) for w in seen)
   rows.append(dict(id=row['id'],site=site,context=dict(latitude=lat,longitude=lon,elevationMeters=0,instantUtc=instant),azimuthDegrees=float(pos.az.deg),altitudeDegrees=float(pos.alt.deg)))
out=ROOT/'tests/ReferenceData/DeepSky/astropy.json';out.parent.mkdir(parents=True,exist_ok=True)
out.write_text(json.dumps(dict(astropyVersion=astropy.__version__,overlaySha256=hashlib.sha256(raw).hexdigest(),toleranceArcminutes=1,warnings=sorted(notes),rows=rows),indent=2)+'\n',encoding='utf-8')
print(f'Frozen {len(rows)} independent airless DSO reference samples; {len(notes)} warning types retained.')
