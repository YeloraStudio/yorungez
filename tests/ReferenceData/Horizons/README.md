# JPL Horizons reference snapshots

These files contain numeric NASA/JPL Horizons observer ephemerides retrieved for public example/synthetic observing sites. No device location or personal record was used. `references.json` preserves the complete request URL, retrieval timestamp, response signature and SHA-256 for each raw response in `raw/`.

Settings: geodetic Earth observer, east-positive longitude, latitude, height in kilometres; UT (UTC for these post-1962 dates), airless apparent body-centre azimuth/elevation. Twelve individual cases and four 24-hour series at five-minute intervals produce 1,168 direction comparisons. Source: [Horizons API](https://ssd-api.jpl.nasa.gov/doc/horizons.html) and [manual](https://ssd.jpl.nasa.gov/horizons/manual.html).

Tests read these files offline. Deliberate refresh: `python scripts/science/refresh_horizons.py --refresh`. Requests are sequential. Refresh can change predicted Earth orientation/model data; review differences before updating the recorded report. The generator publishes normalized data only after all requests parse successfully. Raw responses remain auditable.

Initial thresholds were 1 arcminute direction and 60 seconds for geometric centre/horizon crossings. Two near-pole direction failures are explicitly retained in the report; public azimuth is withheld at absolute latitude >=89 degrees. Passing tests do not mean those original failures disappeared or that all dates/sites are validated. See [method and limitations](../../../docs/astronomi-denemesi.md) and [recorded report](../../../docs/science/astronomy-engine-2.1.19-report.json).
