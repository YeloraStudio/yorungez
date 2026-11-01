# Frozen deep-sky reference

72 independent Astropy/ERFA airless ICRS→AltAz samples: M1, M13, M31, M42, M57 and M104 × Balikesir/Istanbul/Sydney/zero synthetic sites × 2000/2026/2035 instants. J2000 input facts are shared from the SHA-frozen OpenNGC subset; transformation algorithms are independent. This tests the adapter, not independent catalogue truth or all 107 records.

Explicit refresh: `.local/science-venv/Scripts/python.exe scripts/science/refresh_dso_references.py --refresh`. Runtime does not need Python. Astropy 8.0.2 and bundled IERS versions follow the existing [reference environment](../../../scripts/science/requirements-reference.lock.txt); network IERS updates are disabled. The six distinct future-year/IERS warnings are retained. The trial target is 1 arcminute; the initial DSO rotation omits annual aberration, refraction and local terrain. The existing ±89° azimuth restriction remains.

Offline verification: `npm test` in the Web project, or `node --experimental-strip-types tools/science-js/dso-probe.mjs` from the repository root. [Published report](../../../docs/science/deepsky-report.json). No normal test regenerates reference data.
