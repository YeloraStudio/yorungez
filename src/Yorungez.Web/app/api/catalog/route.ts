import catalog from "../../../generated/catalog.json";
import manifest from "../../../generated/manifest.json";
import glossary from "../../../generated/glossary.json";
import overlays from "../../../generated/overlays.json";
import overlayManifest from "../../../generated/overlays-manifest.json";
import { createHash } from "node:crypto";
export async function GET(request: Request) {
  const termHash = createHash("sha256").update(JSON.stringify(glossary)).digest("hex").slice(0, 12);
  const headers = { "Cache-Control": "public, max-age=86400", ETag: `W/"${manifest.derivedSha256}-${overlayManifest.sha256}-${termHash}-2"` };
  if (request.headers.get("If-None-Match") === headers.ETag) return new Response(null, { status: 304, headers });
  const provenance = { version: manifest.version, derivedSha256: manifest.derivedSha256,
    starCount: manifest.starCount, brightCount: manifest.brightCount, constellationCount: manifest.constellationCount,
    sources: manifest.sources, attribution: manifest.attribution, limitations: manifest.limitations };
  // Versioned public assets are verified at build time. A cold identity/API host
  // must never sit on the map's first-frame critical path.
  return Response.json({ catalog: { ...catalog, deepSky: overlays.deepSky, art: overlays.art }, provenance,
    overlayProvenance: { sha256: overlayManifest.sha256, attribution: overlayManifest.attribution }, glossary }, { headers });
}
