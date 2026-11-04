# WMM2025

NOAA NCEI Geomagnetic Modeling Team and British Geological Survey (2024), World Magnetic Model 2025, https://doi.org/10.25921/aqfd-sd83 . Model/software/report: https://www.ncei.noaa.gov/products/world-magnetic-model . Reviewed 4 November 2026.

NCEI identifies the WMM source code as public domain, freely usable and not subject to copyright. This directory identifies the U.S. Government material incorporated in Yorungez; do not relabel it Apache-2.0. Original GeomagnetismLibrary.c/GeomagnetismHeader.h, coefficients, README and official test values are pinned unmodified. No downloaded executable or geoid grid is included. The generated numeric header is a deterministic transcription of WMM.COF; the original Yorungez wrapper remains Apache-2.0.

Validity: 2025.0 inclusive to 2030.0 exclusive. Coordinates are WGS84 geodetic and height above ellipsoid (zero assumed when height is unknown). Declination estimates the main magnetic field only, not local metal, phone cases, storms or device sensor error. Horizontal intensity below 6000 nT is treated conservatively as unsuitable for automatic sky alignment. Source/model validity and device quality gates are separate.
