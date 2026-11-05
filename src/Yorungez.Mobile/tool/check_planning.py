"""Offline native planning ABI: frozen USNO rise/set and pinned Web-engine parity.
Run after check_science.py builds the same wrapper. No network, private coordinates or changed tolerances.
"""
import ctypes as c
import json
import os
import subprocess
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]


def seconds(value):
    return datetime.fromisoformat(value.replace('Z', '+00:00')).timestamp()


def main():
    output = ROOT / '.local/mobile-science'
    lib = c.CDLL(str(output / ('yorungez_sky.dll' if os.name == 'nt' else 'libyorungez_sky.so')))
    lib.yg_crossings.argtypes = [c.c_double]*4 + [c.c_int, c.POINTER(c.c_double), c.c_int]
    lib.yg_crossings.restype = c.c_int

    def calculate(start, end, lat, lon, index):
        raw = (c.c_double*18)()
        assert lib.yg_crossings(start, end, lat, lon, index, raw, 18) == 0
        return [(raw[2+2*i], raw[3+2*i]) for i in range(int(raw[0]))]

    residuals = []
    for name in ['balikesir', 'balikesir-next', 'greenwich', 'sydney', 'kathmandu', 'arctic']:
        fixture = json.loads((ROOT / f'tests/ReferenceData/Observing/{name}.json').read_text(encoding='utf-8'))
        d = fixture['properties']['data']
        lon, lat = fixture['geometry']['coordinates']
        start = datetime(d['year'], d['month'], d['day'], tzinfo=timezone.utc)
        for index, key in [(0, 'sundata'), (1, 'moondata')]:
            actual = calculate(start.timestamp(), (start+timedelta(days=1)).timestamp(), lat, lon, index)
            for event in d[key]:
                if event['phen'] not in ['Rise', 'Set'] or not event['time']:
                    continue
                hour, minute = map(int, event['time'].split(':'))
                expected = start.replace(hour=hour, minute=minute).timestamp()
                candidates = [abs(t-expected) for t, up in actual if up == (event['phen'] == 'Rise')]
                assert candidates, (name, event['phen'])
                residuals.append(min(candidates))
    assert len(residuals) == 22 and max(residuals) <= 180, residuals
    rows = json.loads(subprocess.check_output(['node', str(ROOT / 'tools/science-js/mobile-planning-parity.mjs')]))
    parity = []
    for row in rows:
        actual = calculate(seconds(row['startUtc']), seconds(row['endUtc']), row['latitude'], row['longitude'], row['index'])
        assert len(actual) == len(row['edges']), row['id']
        for a, b in zip(actual, row['edges']):
            assert a[1] == b[1]
            parity.append(abs(a[0]-b[0]))
    # JavaScript Date truncates sub-millisecond instants; no scientific threshold is relaxed.
    assert max(parity) < .002, max(parity)
    raw = (c.c_double*18)()
    assert lib.yg_crossings(seconds('2026-01-01T00:00Z'), seconds('2026-01-02T00:00Z'), 89, 0, 0, raw, 18) == 1
    report = {'status':'passed','engine':'2.1.19','usnoComparisons':len(residuals),'usnoMaxSeconds':max(residuals),
              'usnoToleranceSeconds':180,'webParityWindows':len(rows)//9,'webParityCrossings':len(parity),'webMaxSeconds':max(parity)}
    (output / 'planning-report.json').write_text(json.dumps(report, indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report))


if __name__ == '__main__':
    main()
