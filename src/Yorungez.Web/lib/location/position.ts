import type { ObserverContext } from "../sky/types.ts";
import { validateContext } from "../sky/validation.ts";
export function positionContext(position: Pick<GeolocationPosition, "coords" | "timestamp">, previous: ObserverContext): ObserverContext {
  const c = position.coords;
  if (!Number.isFinite(c.accuracy) || c.accuracy < 0 || !Number.isFinite(position.timestamp)) throw new Error("invalid-position");
  // Geolocation altitude is ellipsoidal and often absent/unreliable. Keep it as
  // sensor metadata; do not silently treat it as verified mean-sea-level height.
  const next: ObserverContext = { ...previous, latitude: c.latitude, longitude: c.longitude,
    elevationMeters: null, placeName:undefined, source: "device", accuracyMeters: c.accuracy, measuredAtUtc: new Date(position.timestamp).toISOString() };
  validateContext(next); return next;
}
