import type { ObserverContext } from "./types.ts";
export const SOLAR_IDS = ["sun", "moon", "mercury", "venus", "mars", "jupiter", "saturn", "uranus", "neptune"] as const;
export function objectCategory(kind: "star" | "solar" | "constellation" | "deepSky", id: string) {
  return kind === "solar" ? id === "sun" ? "star" : id === "moon" ? "moon" : "planet" : kind;
}
export interface SkyFrame {
  sequence: number; context: ObserverContext; catalogVersion: string; canPublishAzimuth: boolean;
  angles: Float64Array; vectors: Float64Array; durationMilliseconds: number;
  equatorialToEnu: Float64Array; artVectors: Float64Array; solarEquatorial: Float64Array;
}
export function belongsToLatest(frame: Pick<SkyFrame, "sequence">, sequence: number) { return frame.sequence === sequence; }
