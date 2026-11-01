import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';
import os from 'node:os';
import { fileURLToPath } from 'node:url';
import * as A from 'astronomy-engine';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const data = JSON.parse(fs.readFileSync(path.join(root, 'tests/ReferenceData/Horizons/references.json')));
const csharp = JSON.parse(fs.readFileSync(path.join(root, '.local/science/csharp-report.json')));
const expected = new Map(csharp.samples.map(s => [s.id + '/' + s.instantUtc, s]));
const samples = [];
const events = [];
function calculate(c, instant) {
  const observer = new A.Observer(c.latitude, c.longitude, c.elevationMeters);
  const time = new Date(instant);
  const eq = A.Equator(A.Body[c.body[0].toUpperCase() + c.body.slice(1)], time, observer, true, true);
  const airless = A.Horizon(time, observer, eq.ra, eq.dec, '');
  const refracted = A.Horizon(time, observer, eq.ra, eq.dec, 'normal');
  return { azimuth: airless.azimuth, altitude: airless.altitude, refractedAltitude: refracted.altitude };
}
const deltaAngle = (a, b) => Math.abs(((a - b + 540) % 360) - 180);
for (const c of [...data.positions, ...data.events]) {
  for (const row of c.rows) {
    const actual = calculate(c, row.instantUtc);
    const other = expected.get(c.id + '/' + row.instantUtc);
    if (!other) throw new Error('Missing C# comparison');
    samples.push({ id: c.id, instantUtc: row.instantUtc,
      azimuthDeltaDegrees: deltaAngle(actual.azimuth, other.azimuthDegrees),
      altitudeDeltaDegrees: Math.abs(actual.altitude - other.altitudeDegrees) });
  }
}
for (const c of data.events) {
  const observer = new A.Observer(c.latitude, c.longitude, c.elevationMeters);
  const body = A.Body[c.body[0].toUpperCase() + c.body.slice(1)];
  const other = csharp.events.find(e => e.id === c.id);
  for (const [direction, key] of [[1, 'risingUtc'], [-1, 'settingUtc']]) {
    const found = A.SearchAltitude(body, observer, direction, new Date(c.instantUtc), 1, 0);
    const actual = found?.date ?? null;
    const reference = other[key] === null ? null : new Date(other[key]);
    events.push({ id: c.id, direction: key,
      deltaSeconds: actual === null || reference === null ? null : Math.abs(actual - reference) / 1000,
      statusesMatch: (actual === null) === (reference === null) });
  }
}
const bench = data.positions[0];
const allBodies = ['sun', 'moon', 'mercury', 'venus', 'mars', 'jupiter', 'saturn', 'uranus', 'neptune'];
function batch() { for (const body of allBodies) calculate({ ...bench, body }, bench.instantUtc); }
for (let i = 0; i < 200; i++) batch();
const elapsed = [];
for (let i = 0; i < 1000; i++) {
  const start = performance.now(); batch(); elapsed.push(performance.now() - start);
}
elapsed.sort((a, b) => a - b);
const browser = fs.readFileSync(path.join(root, 'tools/science-js/node_modules/astronomy-engine/astronomy.browser.min.js'));
const report = {
  schemaVersion: 1, generatedAtUtc: new Date().toISOString(), engine: 'Astronomy Engine', version: '2.1.19',
  environment: { runtime: process.version, os: os.type(), architecture: process.arch, logicalProcessors: os.cpus().length,
    scope: 'Node desktop process; not mobile, browser rendering or worker scheduling' },
  parityTolerances: { coordinateDegrees: 1e-7, crossingSeconds: 0.01 },
  summary: { positionComparisons: samples.length,
    maxAzimuthDeltaDegrees: Math.max(...samples.map(s => s.azimuthDeltaDegrees)),
    maxAltitudeDeltaDegrees: Math.max(...samples.map(s => s.altitudeDeltaDegrees)),
    maxCrossingDeltaSeconds: Math.max(...events.map(e => e.deltaSeconds ?? 0)),
    crossingStatusesMatch: events.every(e => e.statusesMatch) },
  benchmark: { warmupBatches: 200, measuredBatches: 1000, bodiesPerBatch: 9,
    p50Milliseconds: elapsed[499], p95Milliseconds: elapsed[949], p99Milliseconds: elapsed[989], maxMilliseconds: elapsed.at(-1) },
  browserAsset: { file: 'astronomy.browser.min.js', rawBytes: browser.length, gzipBytes: zlib.gzipSync(browser).length },
  samples, events
};
const output = process.argv[2] ? path.resolve(process.argv[2]) : path.join(root, '.local/science/javascript-report.json');
fs.mkdirSync(path.dirname(output), { recursive: true });
fs.writeFileSync(output, JSON.stringify(report, null, 2) + '\n');
if (report.summary.maxAzimuthDeltaDegrees > 1e-7 || report.summary.maxAltitudeDeltaDegrees > 1e-7
    || report.summary.maxCrossingDeltaSeconds > 0.01 || !report.summary.crossingStatusesMatch)
  throw new Error('C#/JavaScript parity target failed; report retained');
console.log(`JavaScript report: ${samples.length} parity comparisons passed; p95 ${elapsed[949].toFixed(4)} ms / 9 bodies.`);
