import type * as Astronomy from "astronomy-engine";
import type { ObserverContext, StarRecord } from "./types.ts";

const AU_PER_PC = 648000 / Math.PI;
const RAD = Math.PI / 180;

/** Catalogue Cartesian space motion + annual/topocentric parallax + first-order
 * annual aberration. Rotation/precession/nutation use the pinned engine.
 * No live IERS EOP, atmospheric refraction or gravitational deflection.
 * This is a scoped, independently sampled model, not an astrometric guarantee.
 */
export function createStarTransform(A: typeof Astronomy, context: ObserverContext) {
  const time = new A.AstroTime(new Date(context.instantUtc));
  const observer = new A.Observer(context.latitude, context.longitude, context.elevationMeters ?? 0);
  const earth = A.BaryState(A.Body.Earth, time);
  const site = A.ObserverVector(time, observer, false);
  const rotation = A.Rotation_EQJ_HOR(time, observer);
  const years = time.tt / 365.25;
  const bx = earth.vx / A.C_AUDAY, by = earth.vy / A.C_AUDAY, bz = earth.vz / A.C_AUDAY;
  return (star: Pick<StarRecord, "positionPc" | "velocityPcPerYear">) => {
    const p = star.positionPc, v = star.velocityPcPerYear;
    let x = (p[0] + v[0] * years) * AU_PER_PC - earth.x - site.x;
    let y = (p[1] + v[1] * years) * AU_PER_PC - earth.y - site.y;
    let z = (p[2] + v[2] * years) * AU_PER_PC - earth.z - site.z;
    const length = Math.hypot(x, y, z);
    x /= length; y /= length; z /= length;
    const dot = x * bx + y * by + z * bz;
    x += bx - dot * x; y += by - dot * y; z += bz - dot * z;
    const horizontal = A.HorizonFromVector(A.RotateVector(rotation, new A.Vector(x, y, z, time)), "");
    return { azimuthDegrees: horizontal.lon, altitudeDegrees: horizontal.lat };
  };
}

/** Stable angular separation, including the azimuth wrap and zenith. */
export function separationArcminutes(azA: number, altA: number, azB: number, altB: number) {
  const a = altA * RAD, b = altB * RAD;
  const dot = Math.sin(a) * Math.sin(b) + Math.cos(a) * Math.cos(b) * Math.cos((azA - azB) * RAD);
  return Math.acos(Math.max(-1, Math.min(1, dot))) / RAD * 60;
}
