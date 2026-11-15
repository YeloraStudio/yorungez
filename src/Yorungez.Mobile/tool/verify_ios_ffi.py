"""Check the dyld exports used by Dart in the packaged iOS executable."""

import argparse
import plistlib
import re
import subprocess
from pathlib import Path


def verify_native_exports(app: Path):
    info = plistlib.loads((app / 'Info.plist').read_bytes())
    executable = app / info['CFBundleExecutable']
    result = subprocess.run(['xcrun', 'dyld_info', '-exports', str(executable)],
                            check=True, capture_output=True, text=True)
    exported = set(re.findall(r'\b_yg_[a-z_]+\b', result.stdout))
    required = {'_yg_abi_version', '_yg_sky', '_yg_crossings', '_yg_eclipses',
                '_yg_satellite_abi', '_yg_satellite', '_yg_magnetic_abi', '_yg_magnetic'}
    if missing := required - exported:
        raise ValueError('Missing iOS runtime exports: ' + ', '.join(sorted(missing)))
    print(f'iOS runtime exports verified ({len(required)} native entry points).')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    verify_native_exports(parser.parse_args().app)
