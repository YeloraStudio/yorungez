# 06 — Data and service catalogue

**Status:** source inventory and ingestion recommendations. **Traceability:** FR-03/04/05/08/09/12. No new catalogue or imagery was downloaded into the product.

## Core sources

| Source / format | Intended use | Rights / operational finding | Proposed mobile treatment |
|---|---|---|---|
| Existing HYG-derived bright catalogue | Stable IDs, bright stars and aliases | Repository attribution; upstream CC BY-SA 4.0 | Bundle the reviewed current subset first |
| OpenNGC plus addendum | NGC/IC, Messier matching, types and physical fields | Upstream CC BY-SA 4.0; fields have recorded provenance | Expand deliberately, retaining source fields and ambiguity |
| Gaia release data | Optional faint-star depth / physical metadata | Official licence and release pages returned HTTP 451 in this research | Candidate only; resolve exact release/access/rights before redistribution |
| HiPS / HEALPix surveys | Registered Milky Way and DSO image depth | Standard is independent of each survey's rights/service policy | Low-resolution reviewed base; optional bounded detail packs |
| JPL Horizons / SSD APIs | Reference calculations, selected solar-system/small-body data | Best effort; serialized, cached, identified requests required | Controlled backend/build ingestion, not every user's render loop |
| USNO | Independent lunar phase and selected event/rise-set references | Documented API, service-specific definitions | Frozen validation and prepared general event data |
| CelesTrak GP/OMM + matching propagator | ISS/satellites and pass prediction | Usage policy and element epoch matter | Modern GP format; refresh via controlled shared ingestion |
| Wikipedia / Wikimedia Commons | Bilingual explanations and object imagery | Page/file-specific attribution, revision and licences | Curated summaries/images with an offline rights manifest |
| NASA media | Selected archive images and educational sources | Third-party content and branding are exceptions to blanket reuse | Review each asset's original page/credit |
| GeoNames | Place labels and general city lookup | Current dump README states CC BY 4.0 | Existing backend, then an explicitly sized offline subset |
| IANA tzdb / zone boundaries | Local civil-time conversion and observer-zone resolution | Rule data and boundary geometry are separate inputs | Version both; online lookup plus a reviewed offline strategy |
| OpenStreetMap-derived maps | Optional Earth location selection | Standard tile server forbids bulk download/prefetch | Online attributed selection; separate permitted source for offline maps |
| Open-Meteo | Optional cloud/weather context | Free hosted API is non-commercial and rate-limited; data licence differs from service entitlement | Assess eligibility; cache/coarsen; keep unknown state when absent |

Primary sources: [HYG licence](https://github.com/astronexus/HYG-Database/blob/main/LICENSE), [OpenNGC README](https://github.com/mattiaverga/OpenNGC/blob/master/README.md), [HiPS Recommendation](https://www.ivoa.net/documents/HiPS/20170519/REC-HIPS-1.0-20170519.pdf), [JPL API policy](https://ssd-api.jpl.nasa.gov/doc/), [USNO](https://aa.usno.navy.mil/data/api), [CelesTrak formats](https://celestrak.org/NORAD/documentation/gp-data-formats.php), [CelesTrak policy](https://celestrak.org/usage-policy.php), [Commons reuse](https://commons.wikimedia.org/wiki/Commons:Reusing_content_outside_Wikimedia), [NASA media](https://www.nasa.gov/nasa-brand-center/images-and-media/), [GeoNames dump](https://download.geonames.org/export/dump/readme.txt), [IANA](https://www.iana.org/time-zones), [OSM tiles](https://operations.osmfoundation.org/policies/tiles/), [Open-Meteo terms](https://open-meteo.com/en/terms).

## Specific findings affecting the plan

**OpenNGC completeness:** upstream explains that M40 and M45 are in its addendum because they have no NGC/IC designation. The current Yorungez subset lacks M40/M45/M102. Importing the main table alone will not fix completeness; identity/provenance review is required for each missing target. [Upstream addendum explanation](https://github.com/mattiaverga/OpenNGC/blob/master/README.md), [current product inventory](../../web-tamamlama-ve-ortak-backend-mobil-hedef.md).

**Satellite formats:** the CelesTrak page currently reports exhaustion of five-digit IDs in July 2026. New objects with six-digit IDs need supported modern formats. Store IDs as stable identifiers with enough range, parse schema/epoch explicitly, and test missing/obsolete/malformed data. Do not treat old TLE parsers as a complete future ingestion solution. [CelesTrak GP documentation](https://celestrak.org/NORAD/documentation/gp-data-formats.php).

**Provider scale:** JPL asks automated users to make one request at a time, identify the application and reuse/cache results. Wikimedia asks for identified, considerate API access. The proposed aggregator must enforce each provider's own concurrency/rate rules rather than using one global aggressive downloader. [JPL fair use](https://ssd-api.jpl.nasa.gov/doc/), [MediaWiki etiquette](https://www.mediawiki.org/wiki/API:Etiquette).

**Maps versus sky:** offline sky support does not require downloading Earth map tiles. OSM's standard tile-server policy excludes bulk prefetch. A future offline Earth map needs a provider or self-hosted package whose licence and service terms permit it. A geocoder's place name is not a new GPS fix. [OSM policy](https://operations.osmfoundation.org/policies/tiles/).

**Weather economics:** free-to-users and advertising-free do not, by themselves, settle whether a hosted provider considers a studio-operated product non-commercial. Verify eligibility and limits; preserve a provider-free sky experience. [Open-Meteo terms](https://open-meteo.com/en/terms).

## Data technologies and boundaries

TAP is a catalogue-access protocol; ADQL adds astronomical query semantics. Use them in controlled catalogue research/ingestion, not as arbitrary mobile SQL entered into a remote service. FITS/WCS describe scientific data and image registration; HiPS supports progressive sky delivery. HEALPix partitions the celestial sphere. None replaces the astronomical position model. [TAP 1.1](https://www.ivoa.net/documents/TAP/), [ADQL 2.1](https://www.ivoa.net/documents/ADQL/), [HiPS](https://www.ivoa.net/documents/HiPS/20170519/REC-HIPS-1.0-20170519.pdf).

PostGIS is relevant to observing places, distance searches, terrain and light-pollution layers on Earth. Q3C/pgSphere and celestial indexing are separate candidates for a much larger atlas; neither is required for the current bright-sky package. Avoid putting every listed scientific standard into the runtime just because it may be useful later.

### Further observing-condition and event candidates

| Candidate | Evidence found | Remaining work |
|---|---|---|
| [International Meteor Organization calendar](https://www.imo.net/calendar/) | Published shower activity/peak and lunar-context information | Select an annual revision; verify reuse/ingestion rights and peak/radiant/time definitions; do not copy an entire editorial calendar |
| [USGS SRTM overview](https://www.usgs.gov/centers/eros/science/usgs-eros-archive-digital-elevation-shuttle-radar-topography-mission-srtm) | Elevation datasets with distinct resolutions/processing | Review product coverage, datum, voids, access/rights, local download size and horizon algorithm |
| [NASA Black Marble](https://blackmarble.gsfc.nasa.gov/) | Official link now redirects to Earthdata; target page returned 403 | Assess product/quality flags, rights and a validated relation to sky brightness before considering a layer |
| [MPCORB](https://minorplanetcenter.net/iau/MPCORB.html) | Attempted official orbital-data page returned 403 | Source/format/rights and propagator suitability remain unverified; JPL prepared-data path is another candidate |

Terrain elevation alone does not describe trees/buildings, and upward nighttime radiance is not automatically a local Bortle class or calibrated astronomical sky brightness. No complete provider, worldwide licence, real-time feed or validated visibility score has been selected for these areas. They remain visible FR-04/05/08 research gaps, not invented data.

## Required provenance record

Proposed record fields: source ID, dataset/release, upstream URL, retrieval time, observation/epoch time where meaningful, ingestion version, checksum, schema, units/frames, licence/attribution, transformation description, validation report, availability/freshness policy and replacement history. Object imagery additionally needs original creator, source revision, derivative/crop note and file-specific rights.

Package preparation time is not the observation time or latest successful provider poll. Retain the previous verified snapshot when refresh fails and expose stale/missing status. Normal builds/tests continue to consume pinned files without silently downloading new scientific data.

## Unavailable or incomplete evidence

ESA's Gaia licence/release pages were unavailable through this research environment (HTTP 451); do not substitute a mirror's claims for a redistribution decision. The CDS HiPS overview timed out, so the accessible IVOA Recommendation supports format statements. Exact per-survey mirroring rights, Gaia release packaging, terrain/light-pollution inputs and final offline search size remain unresolved.
