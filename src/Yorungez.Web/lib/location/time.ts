import { Temporal } from "@js-temporal/polyfill";
export function localInput(instant: string, zone: string) {
  return Temporal.Instant.from(instant).toZonedDateTimeISO(zone).toPlainDateTime().toString({ smallestUnit: "minute" });
}
export function localToUtc(value: string, zone: string, occurrence: "reject" | "earlier" | "later" = "reject") {
  const plain = Temporal.PlainDateTime.from(value);
  const candidate = plain.toZonedDateTime(zone, { disambiguation: occurrence });
  // Even explicit earlier/later cannot invent a clock time in a DST gap.
  if (!candidate.toPlainDateTime().equals(plain)) throw new RangeError("nonexistent-local-time");
  return candidate.toInstant().toString();
}
export function validZone(zone: string) {
  try { new Intl.DateTimeFormat("en", { timeZone: zone }); return true; } catch { return false; }
}
export function timeDraft(instant:string,zone:string,locationZoneReady:boolean){
  const basis=locationZoneReady?"local":"UTC";
  return {basis: basis as "local"|"UTC",value:localInput(instant,locationZoneReady?zone:"UTC")};
}
