export interface StarRecord {
  id: string; hip: number | null; name: string; designation: string; constellation: string;
  raHoursJ2000: number; decDegreesJ2000: number; magnitude: number; colorIndex: number | null;
  distanceParsecs: number | null; positionPc: [number, number, number];
  velocityPcPerYear: [number, number, number]; pmRaMasPerYear: number; pmDecMasPerYear: number;
  radialVelocityKmPerSecond: number | null; inclusion: string;
}
export interface ConstellationRecord { id: string; iau: string; names: { tr: string; en: string }; lines: string[][] }
export interface DeepSkyRecord { id: string; name: string; designation: string; aliases: string[]; type: string; raHoursJ2000: number; decDegreesJ2000: number; magnitude: number | null; majorArcminutes: number | null }
export interface ArtAnchor { x: number; y: number; star: Pick<StarRecord,"id"|"raHoursJ2000"|"decDegreesJ2000"|"positionPc"|"velocityPcPerYear"> }
export interface SkyCatalog { schemaVersion: number; version: string; epoch: string; stars: StarRecord[]; constellations: ConstellationRecord[];
  deepSky?: DeepSkyRecord[]; art?: { figures: { id: string; src: string; size: number[]; anchors: number[] }[]; anchors: ArtAnchor[] } }
export interface ObserverContext { latitude: number; longitude: number; elevationMeters: number | null; instantUtc: string; source?: "example" | "manual" | "device"; accuracyMeters?: number; measuredAtUtc?: string; placeName?:string }
export interface Camera { azimuth: number; altitude: number; fieldOfView: number }
export type Language = "tr" | "en";
