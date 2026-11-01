# Yorungez brand assets

The project owner supplied four PNG originals. They are preserved byte-for-byte in [source/](source/); [provenance.json](provenance.json) records their SHA-256 fingerprints and the derived SVG method. The visual wordmark retains the supplied **Yörüngez** lettering. Application identifiers, URLs, manifest names and accessible product names remain **yorungez**.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="exports/wordmark-on-dark.svg">
  <img src="exports/wordmark-on-light.svg" alt="yorungez" width="360">
</picture>

| Source / export | Purpose |
|---|---|
| [Ivory wordmark original](source/wordmark-cream-original.png) | Reference for light surfaces and the brand palette. |
| [Transparent wordmark original](source/wordmark-transparent-original.png) | Original letter silhouettes for [light](exports/wordmark-on-light.svg) and [dark](exports/wordmark-on-dark.svg) SVGs; no font substitution. |
| [Transparent emblem original](source/mark-original.png) | [Light](exports/mark-on-light.svg) and [dark](exports/mark-on-dark.svg) native SVGs, favicon and maskable launcher emblem. Small extraction flecks are excluded from the native paths. |
| [Illustrated icon original](source/app-icon-original.png) | Visual reference, preserved with its original ivory mat and rounded mockup boundary. |
| [Full-bleed icon master](source/app-icon-fullbleed.png) | Built-in image_gen edit extending the original artwork to square edges; exported to 192/512 px app icons and an opaque 180 px Apple touch icon. The operating system applies its own mask. |
| [Email wordmark](exports/email-wordmark.png) | Opaque 720 px PNG, displayed at 240 px, embedded as a CID resource; no remote image request. |

The palette is `#3C3F43`, `#9EA1A6`, `#8B2333`, `#C9B6A6`, `#F7F1E6`. Dark wordmarks change the graphite letters to ivory while retaining the burgundy final letter and orbit accents. The dark emblem follows the illustrated icon's ivory planet / burgundy orbit. These are brand illustrations, not scientific diagrams.

## Reproducible format exports

From `src/Yorungez.Web`, run `node scripts/export-brand.mjs` explicitly after changing an editable master. Sharp **0.35.5** performs deterministic resizing/rendering; no AI service, desktop folder or API key is required for export or build. Review generated changes before committing.

[assets.json](assets.json) is the shared role-to-URL/dimensions/hash inventory. Web exports live in [public/brand/](../../src/Yorungez.Web/public/brand/) under content-hashed filenames. Keep the provenance fingerprints current when deliberately editing a source. Normal `predev`/`prebuild` verifies all source/export fingerprints and favicon aliases; it does not regenerate artwork. The email PNG is an embedded .NET resource, so a backend-only build does not require Node.

The maskable emblem fits inside the central circle of radius 40% of the image width, with an opaque graphite background outside it. This follows the [Web App Manifest safe-zone definition](https://www.w3.org/TR/appmanifest/#icon-masks). Tests decode actual exported pixels and the 16/32/48 px ICO images. Ordinary and maskable icons have separate manifest purposes.

## Generation record

Only the accepted full-bleed app illustration uses a new raster edit. Tool: **built-in image_gen**, local reference `source/app-icon-original.png`, opaque output. The final selected result is checked into `source/app-icon-fullbleed.png`; discarded wordmark experiments are not production assets. The wordmarks and emblems are native SVG exports of the supplied silhouettes.

Exact accepted prompt:

> Edit the supplied Yorungez illustrated app-icon artwork into a production FULL-BLEED SQUARE app icon. Preserve the same identity and illustration: ivory ö planet with two ivory dots and four-point dark star cutout, burgundy diagonal orbit, small grey orbiting moon, taupe star upper-right, graphite space field, sparse stars, subtle burgundy planet upper-left, dark planet lower-right and gently glowing low horizon. The ONLY required adaptation is removing the exterior cream mat, exterior shadow and baked rounded-square boundary, extending the existing dark space illustration seamlessly to all four corners. Do NOT show a rounded icon on a background: the entire output canvas is the square artwork edge to edge; operating systems will apply rounding themselves. Keep the main emblem recognisable and comfortably centred with breathing room so standard launcher rounding does not clip its essential parts. Match palette #3C3F43 #9EA1A6 #8B2333 #C9B6A6 #F7F1E6 and the supplied refined finish. No letters, no words, no border, no platform UI, no extra emblem.

Project brand assets are included under the repository's [Apache-2.0 licence](../../LICENSE), subject to its trademark provisions in [NOTICE](../../NOTICE). Third-party scientific/media licences remain separate.
