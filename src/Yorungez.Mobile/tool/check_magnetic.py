"""Verify WMM2025 against the official frozen NCEI test table; no network."""
import sys
import ctypes as c
import hashlib
import json
import os
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[3]


def main():
    source = ROOT / 'third-party/wmm2025'
    manifest = json.loads((source / 'manifest.json').read_text(encoding='utf-8'))
    for name, value in manifest['files'].items():
        assert hashlib.sha256((source / name).read_bytes()).hexdigest() == value['sha256']
    out = ROOT / '.local/mobile-science'
    out.mkdir(parents=True, exist_ok=True)
    library = out / ('yorungez_magnetic.dll' if os.name == 'nt' else 'libyorungez_magnetic.so')
    subprocess.run(['gcc','-shared','-O2','-fPIC',*(['-static-libgcc'] if sys.platform != 'darwin' else []),str(ROOT/'src/Yorungez.Mobile/native/yorungez_magnetic.c'),
                    str(source/'GeomagnetismLibrary.c'),'-o',str(library),'-lm'],check=True)
    lib = c.CDLL(str(library))
    assert lib.yg_magnetic_abi() == 1
    lib.yg_magnetic.argtypes = [c.c_double]*4 + [c.POINTER(c.c_double)]
    lib.yg_magnetic.restype = c.c_int
    residuals = []
    for line in (source/'WMM2025_TEST_VALUES.txt').read_text(encoding='utf-8-sig').splitlines():
        if not line.strip() or line.startswith('#'):
            continue
        row = list(map(float,line.split()))
        values = (c.c_double*3)()
        assert lib.yg_magnetic(row[0],row[2],(row[3]+180)%360-180,row[1],values)==0
        residuals.append(abs(values[0]-row[10]))
        assert abs(values[2]-row[7]) < .11
    assert len(residuals)==12 and max(residuals)<.011
    values=(c.c_double*3)()
    assert all(lib.yg_magnetic(year,41,29,0,values)==1 for year in [2024.99,2030,float('nan')])
    report={'status':'passed','model':'WMM2025','referenceComparisons':len(residuals),
            'maxDeclinationResidualDegrees':max(residuals),'invalidDatesRejected':3,
            'note':'Reference table rounding tolerance; not physical phone accuracy.'}
    (out/'magnetic-report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report))


if __name__=='__main__':
    main()
