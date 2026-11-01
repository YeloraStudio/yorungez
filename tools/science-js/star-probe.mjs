import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
import * as A from 'astronomy-engine';
import { createStarTransform, separationArcminutes } from '../../src/Yorungez.Web/lib/sky/star-math.ts';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const bytes = fs.readFileSync(path.join(root, 'data/catalog/bright-sky.json'));
const catalog = JSON.parse(bytes);
const refs = JSON.parse(fs.readFileSync(path.join(root, 'tests/ReferenceData/Stars/astropy.json')));
if (crypto.createHash('sha256').update(bytes).digest('hex') !== refs.catalogSha256) throw new Error('Reference catalogue mismatch');
const stars = new Map(catalog.stars.map(s => [s.id, s]));
const samples = refs.rows.map(row => {
  const actual = createStarTransform(A, row.context)(stars.get(row.starId));
  return { starId: row.starId, site: row.context.id, instantUtc: row.context.instantUtc,
    separationArcminutes: separationArcminutes(actual.azimuthDegrees, actual.altitudeDegrees, row.azimuthDegrees, row.altitudeDegrees),
    altitudeErrorArcminutes: Math.abs(actual.altitudeDegrees - row.altitudeDegrees) * 60 };
});
const context = refs.rows[12].context;
const transform = createStarTransform(A, context);
for (let j = 0; j < 10; j++) for (const s of catalog.stars) transform(s);
const elapsed = [];
for (let j = 0; j < 100; j++) {
  const start = performance.now();
  for (const s of catalog.stars) transform(s);
  elapsed.push(performance.now() - start);
}
elapsed.sort((a,b) => a-b);
const report = { schemaVersion: 1, generatedAtUtc: new Date().toISOString(), engine: 'Astronomy Engine 2.1.19 plus yorungez star adapter',
  reference: `Astropy ${refs.astropyVersion} / ERFA, frozen bundled IERS`, catalogSha256: refs.catalogSha256,
  toleranceArcminutes: refs.positionToleranceArcminutes, referenceWarnings: refs.warnings,
  summary: { samples: samples.length, maxSeparationArcminutes: Math.max(...samples.map(s => s.separationArcminutes)),
    maxAltitudeErrorArcminutes: Math.max(...samples.map(s => s.altitudeErrorArcminutes)) },
  benchmark: { environment: 'local Node desktop, fixed observer/instant, no rendering', starsPerBatch: catalog.stars.length,
    warmupBatches: 10, measuredBatches: 100, p50Milliseconds: elapsed[49], p95Milliseconds: elapsed[94] }, samples };
const output = process.argv[2] ? path.resolve(process.argv[2]) : path.join(root, '.local/catalog/star-report.json');
fs.mkdirSync(path.dirname(output), { recursive: true });
fs.writeFileSync(output, JSON.stringify(report, null, 2) + '\n');
console.log(JSON.stringify(report.summary));
if (report.summary.maxSeparationArcminutes > report.toleranceArcminutes) throw new Error('Star model/reference target failed; report retained');
