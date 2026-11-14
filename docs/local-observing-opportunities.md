# Local observing opportunities

FR-05 and FR-08 · UJ-02 and UJ-03 · AC-06 and AC-10

## User flow

- Web primary navigation follows **Sky**, **Tonight**, **Calendar**, **My Notebook**. **Where should I look?** appears below. Native navigation starts with **Tonight**, **Calendar** and **Where should I look?**. The guide opens with the next 48 hours. The Tonight shortcut uses the selected local night and excludes daytime.
- Supported calendar entries open an assessment around the event. The Web calendar includes calculated lunar eclipses and the supported meteor peaks. The native calendar keeps its existing local events, including solar-eclipse safety guidance.
- The Moon and Mercury, Venus, Mars, Jupiter and Saturn link from their detail cards. The guide presents local time with its time-zone offset and UTC, direction and altitude, and a shortcut into the sky simulation. For showers the direction is the radiant. Meteors can appear across the sky.
- **Calendar → 30-day observing plan** opens a bounded local date picker, target filter and day detail. The client requests only the selected day using local midnight boundaries. The Moon card shows its phase category and illuminated fraction at the midpoint of that day.
- Verified users may schedule a weather-dependent email for a displayed favorable window or a future astronomical window beyond the weather horizon. The date must fall within the 30 local calendar dates. The same scheduler checks the live forecast shortly before the chosen time. These are one-time reminders. The native Reminders screen and Web guide expose cancellation.

## Calculation and forecast

The shared API samples the pinned Astronomy Engine at five-minute intervals. Times near thresholds are approximate. Lunar daylight criteria use illumination, angular separation from the Sun and altitude. Planet criteria use altitude, solar altitude and apparent magnitude. Eclipse phases use contacts and local geometric Moon altitude. Meteor windows use the radiant, astronomical darkness, proximity to the selected peak and moonlight. The four peak entries are from the 2026/2027 International Meteor Organization calendars, matching the original native selection. Calendar coverage is finite and should be renewed before the listed peaks run out.

MET Norway provides the regional hourly cloud fields. Its global data model is approximately 9 km outside its higher-resolution regional models. The service shares one forecast per 0.1° lookup cell in Redis, uses provider refresh headers and sends conditional requests. It excludes expired or missing data from the weather grades and checks forecast age before using it. Fog and cloud layers are optional provider fields. Conditions describe a planning heuristic. The model cannot assess a cloud in the exact line of sight, trees or buildings, local light pollution, or the user's eyesight. It does not publish a probability of seeing something. The existing polar azimuth limit remains in place.

The anonymous API accepts coordinates only in a JSON POST with `Cache-Control: no-store`. Exact calculation inputs are used transiently. MET Norway receives the cell center. Weather-dependent reminders store a rounded site until cancellation, successful delivery, suppression, terminal failure, or expiry. The scheduler shares the existing verified-account reminder channel and checks the current plan before sending a branded English email. Weather-aware email is suppressed if conditions are no longer favorable.

## Enable live weather

A deployment operator reads and accepts the MET Norway terms and sets `ObservingForecast__MetNoUserAgent` to identify Yorungez and provide an operator contact. The production stack passes the private Portainer setting `MET_NO_USER_AGENT` into this variable. With the variable empty, the guide supplies astronomical windows and labels weather unavailable. The adapter caps each process at five request starts per second and shares responses in Redis. Reassess the combined request budget before scaling beyond one API process. The feature uses open weather data and the existing Redis, PostgreSQL and email delivery. Forecast ingestion at larger scale can be evaluated independently.

For a local pilot, set `ObservingForecast__MetNoUserAgent` in the API process environment with an identifying value such as `Yorungez/1.0 (+https://github.com/YeloraStudio/yorungez)`. Start the API with `./scripts/Start-LocalBackend.ps1 -EmailMode Mailpit`. Submit a public test location to `POST /api/v1/sky/observing-opportunities`. Check that `weatherStatus` is `available`, `weatherUpdatedUtc` is present, and eligible windows contain a cloud fraction. For production, update the server's Compose copy as well as its private environment. The deployment workflow updates images using the server's Compose file.

Field acceptance includes observed daytime and nighttime results, comparing reminder outcomes against actual sky conditions, and checking native binaries on physical Android and iOS devices. The current delivery does not include automated recurring subscriptions, a second data provider, or sighting-report collection.

Local verification covered 175 .NET tests using PostgreSQL and Redis, 81 Web tests and the Next.js production build, and 108 Flutter tests plus static analysis. Chromium checks covered the Turkish mobile-width and English desktop menus, Tonight-to-guide and back navigation, and the Calendar-to-Geminids-to-map flow. Weather-provider responses and outbound mail were simulated. The Windows Flutter checks used the available 3.41.6 SDK. The project release pin remains 3.47.9.

The activation preflight applied the notebook migration to the local development database, verified API and Mailpit health, and passed all 176 .NET Release tests. The weather tests cover cache sharing, coordinate rounding and conditional revalidation with a simulated `304 Not Modified` response. The production Compose template passed configuration validation and the Web production build passed with the provider credit and license link.

The owner confirmed acceptance of the MET Norway terms on 14 November 2026. The local API was configured in ignored development settings and the Web proxy returned a live Moon forecast for the public Balıkesir city coordinates. The first response contained cloud values for all 11 windows, with three favorable, three uncertain and five poor. A second request returned the same forecast release. Live smoke tests also returned graded windows for Tromsø, Singapore and Cape Town. A Chromium check at 390 px confirmed that the Turkish screen displays live cloud values, provider attribution and the license link without horizontal overflow.

A verified local pilot account scheduled a Moon reminder for Lisbon, where the forecast had a favorable near-term window. The regular scheduler rechecked the live forecast and delivered to local Mailpit with azimuth, elevation, and provider attribution. The reminder reached the `sent` state and the account was deleted through the API after verification.

The 30-day follow-up was tested against the local API on the Pixel 8 Pro Android emulator (API 35). The Calendar opened the plan, the current date displayed live weather and a lunar phase, and the 24 November selection displayed the Moon's geometry and the conditional reminder action with weather pending. Chromium verified the Turkish date-picker flow at 390 px. A separate verified local account scheduled, read and cancelled a conditional email for day +10. The scheduler's near-term delivery was also verified in the Lisbon pilot above.

- [MET Norway data model](https://docs.api.met.no/doc/locationforecast/datamodel.html) · [MET Norway usage and attribution](https://docs.api.met.no/doc/TermsOfService.html)
- [U.S. Naval Observatory crescent visibility](https://aa.usno.navy.mil/faq/crescent) · [NASA planet visibility](https://science.nasa.gov/solar-system/skywatching/planetary-alignments-and-planet-parades/)
- [NASA lunar eclipse contacts](https://science.nasa.gov/solar-system/moon/march-2026-total-lunar-eclipse-your-questions-answered/) · [IMO 2026–2027 calendars](https://www.imo.net/calendar/)
