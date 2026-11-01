import { find } from "geo-tz/all";
import { readJson } from "../../../../lib/http/read-json.ts";
export const runtime = "nodejs";
export async function POST(request: Request) {
  const headers = { "Cache-Control": "no-store" };
  try {
    const input = await readJson(request) as { latitude: number; longitude: number };
    if (!Number.isFinite(input.latitude) || Math.abs(input.latitude) > 90 || !Number.isFinite(input.longitude) || Math.abs(input.longitude) > 180) throw new Error("coordinates");
    return Response.json({ zones: find(input.latitude, input.longitude), source: "geo-tz-8.1.10", model: "timezone-boundary-builder-comprehensive" }, { headers });
  } catch { return Response.json({ code: "Location.InvalidCoordinates" }, { status: 400, headers }); }
}
