import assert from "node:assert/strict";
import test from "node:test";
import fs from "node:fs";
import crypto from "node:crypto";
import * as A from "astronomy-engine";
import { createStarTransform, separationArcminutes } from "../lib/sky/star-math.ts";
import { buildFrame } from "../lib/sky/frame.ts";
import { belongsToLatest, objectCategory, SOLAR_IDS } from "../lib/sky/frame-contract.ts";
import { validateContext } from "../lib/sky/validation.ts";
import { horizontalVector, normalizedCamera, pickObject, projector } from "../lib/sky/projection.ts";
import { messages } from "../lib/i18n.ts";
import type { SkyCatalog, ObserverContext } from "../lib/sky/types.ts";
const read = (file: string) => fs.readFileSync(new URL(file, import.meta.url));
const bytes = read("../../../data/catalog/bright-sky.json");
const catalog = JSON.parse(bytes.toString()) as SkyCatalog;
const manifest = JSON.parse(read("../../../data/catalog/manifest.json").toString());
const starRefs = JSON.parse(read("../../../tests/ReferenceData/Stars/astropy.json").toString());
const planetRefs = JSON.parse(read("../../../tests/ReferenceData/Horizons/references.json").toString());
const empty: SkyCatalog = { schemaVersion: 1, version: "test", epoch: "J2000.0", stars: [], constellations: [] };
const context: ObserverContext = { latitude: 41.0082, longitude: 28.9784, elevationMeters: null, instantUtc: "2026-10-30T20:00:00Z" };

test("catalogue fingerprint, 88 distinct identities, complete bilingual names and all figure nodes", () => {
  assert.equal(crypto.createHash("sha256").update(bytes).digest("hex"), manifest.derivedSha256);
  const ids = new Set(catalog.stars.map(s => s.id));
  assert.equal(ids.size, 5073); assert.equal(catalog.constellations.length, 88);
  assert.equal(new Set(catalog.constellations.map(c => c.id)).size, 88);
  assert.equal(catalog.stars.filter(s => s.inclusion === "bright").length, 5070);
  for (const s of catalog.stars) { assert.ok(s.distanceParsecs === null || s.distanceParsecs > 0 && s.distanceParsecs < 100000); }
  for (const c of catalog.constellations) {
    assert.ok(c.names.tr && c.names.en); for (const id of c.lines.flat()) assert.ok(ids.has(id));
  }
  assert.equal(catalog.constellations.filter(c => c.iau === "Ser").length, 1);
});
test("all 144 independent Astropy samples stay within the declared stellar target", () => {
  assert.equal(starRefs.catalogSha256, manifest.derivedSha256);
  for (const row of starRefs.rows) {
    const star = catalog.stars.find(s => s.id === row.starId)!;
    const actual = createStarTransform(A, row.context)(star);
    assert.ok(separationArcminutes(actual.azimuthDegrees, actual.altitudeDegrees, row.azimuthDegrees, row.altitudeDegrees) <= 1, `${row.starId} ${row.context.id}`);
  }
});
test("worker Solar System path matches the frozen independent JPL position cases", () => {
  for (const c of planetRefs.positions) {
    const frame = buildFrame(empty, { latitude: c.latitude, longitude: c.longitude, elevationMeters: c.elevationMeters, instantUtc: c.instantUtc }, 1);
    const index = SOLAR_IDS.indexOf(c.body), row = c.rows[0];
    if (Math.abs(c.latitude) >= 89) { assert.equal(frame.canPublishAzimuth, false); continue; }
    assert.ok(separationArcminutes(frame.angles[index*2], frame.angles[index*2+1], row.azimuthDegrees, row.altitudeDegrees) <= 1, c.id);
  }
});
test("frame identity layout and double-precision observer context remain intact", () => {
  const input = { ...context, latitude: 41.12345678901234, longitude: 29.98765432109876 };
  const frame = buildFrame(catalog, input, 7);
  assert.equal(frame.context.latitude, input.latitude); assert.equal(frame.context.longitude, input.longitude);
  assert.equal(frame.sequence, 7); assert.equal(frame.angles.length, (5073 + 9 + 88) * 2);
  assert.ok([...frame.angles].every(Number.isFinite));
});
test("an older result cannot replace a newer requested context", () => {
  assert.equal(belongsToLatest({ sequence: 5 }, 6), false);
  assert.equal(belongsToLatest({ sequence: 6 }, 6), true);
});
test("numeric zero and exact endpoints remain valid; malformed calendar inputs are not normalized", () => {
  validateContext({ ...context, latitude: 0, longitude: 0 });
  validateContext({ ...context, latitude: -90, longitude: 180, instantUtc: "2024-02-29T12:00:00Z" });
  for (const instant of ["2026-02-30T12:00:00Z", "2026-10-30T24:00:00Z", "2026-10-30T12:00:00", "2036-01-01T00:00:00Z", "2026-10-30T12:00:00+14:30"])
    assert.throws(() => validateContext({ ...context, instantUtc: instant }));
  assert.throws(() => validateContext({ ...context, latitude: NaN }));
  assert.throws(() => validateContext({ ...context, longitude: 181 }));
});
test("projection keeps east to the right of north and handles azimuth wrap without a seam", () => {
  const p = projector({ azimuth: 0, altitude: 0, fieldOfView: 100 }, 1200, 700);
  const north = p(...horizontalVector(0, 0))!, east = p(...horizontalVector(30, 0))!, west = p(...horizontalVector(330, 0))!;
  assert.equal(north[0], 600); assert.equal(north[1], 350); assert.ok(east[0] > 600); assert.ok(west[0] < 600);
  assert.ok(Math.abs(p(...horizontalVector(360, 0))![0] - 600) < 1e-9);
  assert.equal(p(...horizontalVector(180, 0)), null);
  const view = normalizedCamera({ azimuth: -1, altitude: 100, fieldOfView: 600 });
  assert.deepEqual(view, { azimuth: 359, altitude: 90, fieldOfView: 330 });
});
test("pointer hit testing returns canonical identity, ignoring clipped and distant points", () => {
  const points = new Float32Array([100, 100, NaN, NaN, 200, 200]);
  assert.equal(pickObject(points, ["sun", "hyg-1", "hyg-32263"], 202, 199), "hyg-32263");
  assert.equal(pickObject(points, ["sun", "hyg-1", "hyg-32263"], 400, 400), null);
});
test("all frontend message keys and Solar System labels have both complete languages", () => {
  assert.equal(objectCategory("solar", "sun"), "star");
  assert.equal(objectCategory("solar", "moon"), "moon");
  assert.equal(objectCategory("solar", "saturn"), "planet");
  assert.deepEqual(Object.keys(messages.tr).sort(), Object.keys(messages.en).sort());
  for (const language of ["tr", "en"] as const) {
    for (const value of Object.values(messages[language])) if (typeof value === "string") assert.ok(value.trim());
    assert.deepEqual(Object.keys(messages[language].celestialNames).sort(), [...SOLAR_IDS].sort());
  }
});
