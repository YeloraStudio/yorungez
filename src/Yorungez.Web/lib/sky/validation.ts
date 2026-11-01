import type { ObserverContext } from "./types.ts";
export function validateContext(context: ObserverContext) {
  if (!Number.isFinite(context.latitude) || Math.abs(context.latitude) > 90
      || !Number.isFinite(context.longitude) || Math.abs(context.longitude) > 180) throw new Error("coordinates");
  const parts = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.\d{1,7})?(Z|([+-])(\d{2}):(\d{2}))$/i.exec(context.instantUtc);
  if (!parts) throw new Error("instant");
  const [year, month, day, hour, minute, second] = parts.slice(1, 7).map(Number);
  const calendar = new Date(Date.UTC(year, month - 1, day, hour, minute, second));
  if (calendar.getUTCFullYear() !== year || calendar.getUTCMonth() !== month - 1
      || calendar.getUTCDate() !== day || hour > 23 || minute > 59 || second > 59
      || (parts[9] && (Number(parts[9]) > 14 || Number(parts[10]) > 59
        || (Number(parts[9]) === 14 && Number(parts[10]) !== 0)))) throw new Error("instant");
  const time = Date.parse(context.instantUtc);
  if (!Number.isFinite(time) || time < Date.UTC(2000, 0, 1) || time >= Date.UTC(2036, 0, 1)) throw new Error("dateRange");
  if (context.elevationMeters !== null && (!Number.isFinite(context.elevationMeters)
      || context.elevationMeters < -500 || context.elevationMeters > 10000)) throw new Error("elevation");
}
