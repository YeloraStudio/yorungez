# Independent standard rise/set reference sample

Six frozen USNO daily responses, UTC/UT offset 0: Balıkesir 2026-10-31/11-01, Sydney 2026-06-21, Greenwich 2026-10-25, Kathmandu 2026-10-31, Longyearbyen 2026-06-21. Public example points are not a user's measured GPS. `manifest.json` holds URLs, SHA-256, dates and a **180 s** declared comparison threshold.

**22 Sun/Moon Rise/Set facts**, Astronomy Engine 2.1.19 SearchRiseSet at 0 m reference elevation; maximum difference **25.48 s**. USNO UT published to minute precision is treated as UTC at that precision. Longyearbyen polar day has no solar rise/set in the window; null is not invented 00:00. [Numeric report](../../../docs/science/observing-reference-report.json).

Standard model uses 34 arcmin atmospheric refraction and upper limb for Sun/Moon. It is separate from the map/API airless centre/0-degree crossing. No terrain, geoid conversion, weather or naked-eye detection verification is implied. Six site/date files and two bodies do not certify all targets, years, polar cases or elevations.

Normal `npm test` reads these files and checks SHA/deltas without the network. Explicit source acquisition only:

```powershell
python scripts/science/refresh_observing_references.py --refresh
```

[USNO API documentation](https://aa.usno.navy.mil/data/api), [USNO complete Sun/Moon daily data](https://aa.usno.navy.mil/data/RS_OneDay). Previously recorded JPL polar exceptions remain unchanged.
