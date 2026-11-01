import { validateContext } from "./validation.ts";
import * as A from "astronomy-engine";
import { createStarTransform } from "./star-math.ts";
import type { ObserverContext, SkyCatalog } from "./types.ts";
import { SOLAR_IDS } from "./frame-contract.ts";
import type { SkyFrame } from "./frame-contract.ts";
const RAD = Math.PI / 180;
export function buildFrame(catalog: SkyCatalog, context: ObserverContext, sequence: number): SkyFrame {
  validateContext(context);
  const start = performance.now();
  const count = catalog.stars.length + SOLAR_IDS.length + catalog.constellations.length + (catalog.deepSky?.length ?? 0);
  const angles = new Float64Array(count * 2), vectors = new Float64Array(count * 3);
  function put(index: number, az: number, alt: number) {
    angles[index * 2] = az; angles[index * 2 + 1] = alt;
    vectors[index * 3] = Math.cos(alt * RAD) * Math.sin(az * RAD);
    vectors[index * 3 + 1] = Math.cos(alt * RAD) * Math.cos(az * RAD);
    vectors[index * 3 + 2] = Math.sin(alt * RAD);
  }
  const transform = createStarTransform(A, context);
  const indices = new Map<string, number>();
  catalog.stars.forEach((star, i) => {
    indices.set(star.id, i);
    const result = transform(star);
    put(i, result.azimuthDegrees, result.altitudeDegrees);
  });
  const date = new Date(context.instantUtc);
  const observer = new A.Observer(context.latitude, context.longitude, context.elevationMeters ?? 0);
  const time = new A.AstroTime(date), rotation = A.Rotation_EQJ_HOR(time, observer);
  const equatorialToEnu = new Float64Array(9), solarEquatorial = new Float64Array(27);
  for (let i = 0; i < 3; i++) {
    const v = A.RotateVector(rotation, new A.Vector(i === 0 ? 1 : 0, i === 1 ? 1 : 0, i === 2 ? 1 : 0, time));
    equatorialToEnu.set([-v.y, v.x, v.z], i * 3);
  }
  SOLAR_IDS.forEach((id, i) => {
    const body = id[0].toUpperCase() + id.slice(1) as A.Body;
    const equ = A.Equator(body, date, observer, true, true);
    solarEquatorial.set([equ.ra, equ.dec, equ.dist], i * 3);
    const hor = A.Horizon(date, observer, equ.ra, equ.dec, "");
    put(catalog.stars.length + i, hor.azimuth, hor.altitude);
  });
  catalog.constellations.forEach((pattern, i) => {
    let x = 0, y = 0, z = 0;
    for (const id of new Set(pattern.lines.flat())) {
      const index = indices.get(id)!;
      x += vectors[index * 3]; y += vectors[index * 3 + 1]; z += vectors[index * 3 + 2];
    }
    put(catalog.stars.length + SOLAR_IDS.length + i,
      (Math.atan2(x, y) / RAD + 360) % 360, Math.atan2(z, Math.hypot(x, y)) / RAD);
  });
  catalog.deepSky?.forEach((object, i) => {
    const ra = object.raHoursJ2000 * 15 * RAD, dec = object.decDegreesJ2000 * RAD;
    const hor = A.HorizonFromVector(A.RotateVector(rotation, new A.Vector(Math.cos(dec) * Math.cos(ra), Math.cos(dec) * Math.sin(ra), Math.sin(dec), time)), "");
    put(catalog.stars.length + 9 + catalog.constellations.length + i, hor.lon, hor.lat);
  });
  const artVectors = new Float64Array((catalog.art?.anchors.length ?? 0) * 3);
  catalog.art?.anchors.forEach((anchor, i) => {
    const point = transform(anchor.star), az = point.azimuthDegrees * RAD, alt = point.altitudeDegrees * RAD;
    artVectors.set([Math.cos(alt) * Math.sin(az), Math.cos(alt) * Math.cos(az), Math.sin(alt)], i * 3);
  });
  return { sequence, context, catalogVersion: catalog.version, canPublishAzimuth: Math.abs(context.latitude) < 89,
    angles, vectors, equatorialToEnu, artVectors, solarEquatorial, durationMilliseconds: performance.now() - start };
}

