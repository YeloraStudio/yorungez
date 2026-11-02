import assert from 'node:assert/strict';
import test from 'node:test';
import fs from 'node:fs';
import {calculationStatus} from '../lib/sky/data-status.ts';
import {scienceStatus} from '../scripts/science-status.mjs';
const context={latitude:41,longitude:29,elevationMeters:null,instantUtc:'2026-11-02T08:00:00Z'},now=Date.parse(context.instantUtc);
test('live, simulated, delayed and mismatched calculation contexts are distinguished',()=>{
 assert.equal(calculationStatus(null,context,'live',false,now),'waiting');
 assert.equal(calculationStatus(context,context,'live',false,now+1000),'live');
 assert.equal(calculationStatus(context,context,'live',false,now+10001),'delayed');
 assert.equal(calculationStatus(context,context,'live',true,now),'error');
 assert.equal(calculationStatus({...context,latitude:0},context,'live',false,now),'updating');
 assert.equal(calculationStatus({...context,elevationMeters:250},context,'live',false,now),'updating');
 assert.equal(calculationStatus(context,context,'simulation',false,now+86400000),'simulation');
 assert.equal(calculationStatus({...context,instantUtc:'2020-01-01T00:00:00Z'},context,'simulation',false,now),'updating');
});
test('display metadata retains source preparation times rather than inventing freshness at build time',()=>{
 const read=(file:string)=>JSON.parse(fs.readFileSync(new URL(file,import.meta.url),'utf8'));
 const stars=read('../../../data/catalog/manifest.json'),overlays=read('../../../data/catalog/overlays-manifest.json'),events=read('../../../data/events/manifest.json');
 const status=scienceStatus(stars,overlays,events,'2.1.19');
 assert.equal(status.stars.preparedAtUtc,stars.generatedAtUtc);assert.equal(status.deepSky.preparedAtUtc,overlays.generatedAtUtc);assert.equal(status.events.preparedAtUtc,events.generatedAtUtc);
 assert.equal(status.stars.count,5073);assert.equal(status.deepSky.count,107);assert.equal(status.events.count,2623);
 assert.equal(scienceStatus({...stars,generatedAtUtc:undefined},overlays,events,'2.1.19').stars.preparedAtUtc,null);
});
