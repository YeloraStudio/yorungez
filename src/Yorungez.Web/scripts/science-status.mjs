// Dataset preparation times come only from source manifests, never from the current build time.
export function scienceStatus(stars,overlays,events,engineVersion){
 const timestamp=value=>typeof value==='string'&&Number.isFinite(Date.parse(value))?value:null;
 return {schemaVersion:1,engineVersion,
  stars:{version:stars.version,preparedAtUtc:timestamp(stars.generatedAtUtc),count:stars.starCount,constellations:stars.constellationCount},
  deepSky:{preparedAtUtc:timestamp(overlays.generatedAtUtc),count:overlays.deepSkyCount},
  events:{preparedAtUtc:timestamp(events.generatedAtUtc),count:events.eventCount,phaseReferenceCount:events.phaseReferenceCount,engineVersion:events.engineVersion}};
}
