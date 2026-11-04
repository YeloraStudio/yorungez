"""Offline native SGP4 verification against official Vallado TEME results.

No production elements are bundled. Builds the same wrapper used by mobile.
Optional --astropy adds an independent TEME/observer comparison with matched
UT1=UTC and polar motion=0, using the separately prepared science environment.
"""
import ctypes as c
from datetime import datetime, timedelta, timezone
import hashlib
import json
import math
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[3]
UP = ROOT / 'third-party/sgp4'
OUT = ROOT / '.local/mobile-science'


def exponent(value):
    return float(value[:6]) * 1e-5 * 10 ** int(value[6:])


def main():
    manifest = json.loads((UP / 'manifest.json').read_text(encoding='utf-8'))
    for name, entry in manifest['files'].items():
        assert hashlib.sha256((UP / name).read_bytes()).hexdigest() == entry['sha256']
    OUT.mkdir(parents=True, exist_ok=True)
    library = OUT / ('yorungez_satellite.dll' if os.name == 'nt' else 'libyorungez_satellite.so')
    subprocess.run(['g++', '-shared', '-O2', '-fPIC', '-static-libgcc', '-static-libstdc++',
                    str(ROOT / 'src/Yorungez.Mobile/native/yorungez_satellite.cpp'),
                    str(UP / 'SGP4.cpp'), '-o', str(library)], check=True)
    lib = c.CDLL(str(library))
    assert lib.yg_satellite_abi() == 1
    lib.yg_satellite.argtypes = [c.POINTER(c.c_double)] + [c.c_double]*4 + [c.POINTER(c.c_double), c.c_int]
    lib.yg_satellite.restype = c.c_int
    lines = (UP / 'SGP4-VER.TLE').read_text(encoding='ascii').splitlines()
    comparisons, position, velocity, samples = 0, [], [], []
    for identity in ['00005', '06251', '08195']:
        first = next(i for i, line in enumerate(lines) if line.startswith('1 ' + identity))
        one, two = lines[first:first+2]
        year = int(one[18:20])
        epoch = datetime(2000+year if year < 57 else 1900+year, 1, 1, tzinfo=timezone.utc) + timedelta(days=float(one[20:32])-1)
        elements = [epoch.timestamp(), exponent(one[53:61]), float(one[33:43]), exponent(one[44:52]),
                    float('0.'+two[26:33]), float(two[34:42]), float(two[8:16]), float(two[43:51]), float(two[52:63]), float(two[17:25])]
        start = False
        for line in (UP / (identity+'.e')).read_text(encoding='ascii').splitlines():
            if line.strip() == 'EphemerisTimePosVel':
                start = True
                continue
            parts = line.split()
            if not start or len(parts) != 7:
                continue
            try:
                reference = list(map(float, parts))
            except ValueError:
                continue
            seconds = reference[0]
            if abs(seconds) > 7*86400:
                continue
            result = (c.c_double*9)()
            status = lib.yg_satellite((c.c_double*10)(*elements), epoch.timestamp()+seconds, 41.0082, 28.9784, 0, result, 9)
            assert status == 0, (identity, seconds, status)
            position.append(max(abs(result[i]-reference[i+1]) for i in range(3)))
            velocity.append(max(abs(result[i+3]-reference[i+4]) for i in range(3)))
            comparisons += 1
            if seconds in [0, 21600, 43200]:
                samples.append((epoch.timestamp()+seconds, list(result)))
    assert comparisons > 30 and max(position) < 2e-5 and max(velocity) < 2e-8, (comparisons,max(position),max(velocity))
    result = (c.c_double*9)()
    invalid = lib.yg_satellite((c.c_double*10)(*[0]*10), 0, 41, 29, 0, result, 9)
    assert invalid == 1
    report = {'status':'passed','reference':'Vallado AIAA-2006-6753 official .e results','comparisons':comparisons,
              'maximumPositionKm':max(position),'maximumVelocityKmPerSecond':max(velocity),'invalidElementsRejected':1}
    if '--astropy' in sys.argv:
        import numpy as np
        import astropy.units as u
        from astropy.coordinates import TEME, ITRS, AltAz, EarthLocation, CartesianRepresentation
        from astropy.time import Time
        from astropy.utils import iers
        iers.conf.auto_download = False
        # Explicit matching frame assumptions, not silently mixing live IERS EOP.
        table = iers.IERS_B.open(iers.IERS_B_FILE)
        table['PM_x'][:] = 0*u.arcsec
        table['PM_y'][:] = 0*u.arcsec
        residuals = []
        observer = EarthLocation.from_geodetic(28.9784*u.deg,41.0082*u.deg,0*u.m)
        with iers.earth_orientation_table.set(table):
            for stamp, raw in samples:
                instant = Time(stamp,format='unix',scale='utc')
                instant.delta_ut1_utc = 0
                itrs = TEME(CartesianRepresentation(np.array(raw[:3])*u.km),obstime=instant).transform_to(ITRS(obstime=instant))
                topo = ITRS(itrs.cartesian-observer.get_itrs(obstime=instant).cartesian,obstime=instant,location=observer)
                altaz = topo.transform_to(AltAz(obstime=instant,location=observer,pressure=0*u.hPa))
                residuals.append(max(abs((altaz.az.deg-raw[6]+180)%360-180),abs(altaz.alt.deg-raw[7])))
        assert max(residuals) < 1e-5, residuals
        report['astropyObserver']={'comparisons':len(residuals),'maximumDegrees':max(residuals),'ut1MinusUtcSeconds':0,'polarMotionArcseconds':0}
    (OUT/'satellite-report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report))


if __name__ == '__main__':
    main()
