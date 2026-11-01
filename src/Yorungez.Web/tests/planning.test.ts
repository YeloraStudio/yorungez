import assert from 'node:assert/strict';import test from 'node:test';import fs from 'node:fs';import crypto from 'node:crypto';
import * as A from 'astronomy-engine';import {buildObservingPlan,nightBounds,bodyAltitude} from '../lib/sky/planning.ts';import {intervalInstant} from '../lib/sky/planning-navigation.ts';
import {calendarMonth,searchPlaces,nearestPlace} from '../lib/server/planning-catalog.ts';
import {GET as calendarGET} from '../app/api/calendar/route.ts';import {POST as placesPOST} from '../app/api/location/places/route.ts';
import {horizontalVector,normalizedCamera,projector} from '../lib/sky/projection.ts';import {screenRay} from '../lib/sky/natural-scene.ts';import {terrainOpacity} from '../lib/sky/terrain.ts';import {planningText} from '../lib/planning-text.ts';
const read=(p:string)=>fs.readFileSync(new URL(p,import.meta.url));
const context={latitude:39.6484,longitude:27.8826,elevationMeters:null,instantUtc:'2026-10-31T14:00:00Z'};
test('wide stereographic view includes the rear hemisphere without projecting the antipode',()=>{
 const camera=normalizedCamera({azimuth:0,altitude:-90,fieldOfView:600});assert.equal(camera.fieldOfView,330);
 const project=projector(camera,1280,720);assert.ok(project(...horizontalVector(150,25)));assert.equal(project(...horizontalVector(0,90)),null);
 for(const [x,y] of [[0,0],[640,360],[1280,720]]){const point=project(...screenRay(camera,1280,720,x,y));assert.ok(point);assert.ok(Math.hypot(point[0]-x,point[1]-y)<1e-7)}
 assert.equal(terrainOpacity(30,false),1);assert.ok(terrainOpacity(-40,false)<.2);assert.ok(terrainOpacity(30,true)<.2);
});
test('night windows honor DST and intersect target intervals with sunset/sunrise, including polar cases',()=>{
 const spring=nightBounds('America/New_York','2026-03-07');
 const autumn=nightBounds('America/New_York','2026-10-31');
 assert.equal(Date.parse(spring.endUtc)-Date.parse(spring.startUtc),23*3600000);assert.equal(Date.parse(autumn.endUtc)-Date.parse(autumn.startUtc),25*3600000);
 const plan=buildObservingPlan(context,'Europe/Istanbul','2026-10-31');assert.equal(plan.rows.length,8);const high=buildObservingPlan({...context,elevationMeters:2500},'Europe/Istanbul','2026-10-31');assert.deepEqual(high.rows.map(r=>r.intervals),plan.rows.map(r=>r.intervals));assert.match(plan.definition,/sea-level 0 m/);assert.ok(plan.sunriseUtc&&plan.sunsetUtc&&plan.sunriseUtc>plan.sunsetUtc);
 for(const row of plan.rows){for(const i of row.intervals){assert.ok(i.startUtc>=plan.startUtc&&i.endUtc<=plan.endUtc&&i.endUtc>i.startUtc);const keyboard=intervalInstant(i,row.bestInstantUtc,null);assert.ok(keyboard>i.startUtc&&keyboard<i.endUtc);assert.ok(intervalInstant(i,row.bestInstantUtc,-1)>i.startUtc);assert.ok(intervalInstant(i,row.bestInstantUtc,2)<i.endUtc)}if(row.bestInstantUtc)assert.ok(row.intervals.some(i=>row.bestInstantUtc!>=i.startUtc&&row.bestInstantUtc!<=i.endUtc));}
 const pole=buildObservingPlan({...context,latitude:78.2232,longitude:15.6469},'Arctic/Longyearbyen','2026-06-21');assert.equal(pole.sunsetUtc,null);assert.equal(pole.sunriseUtc,null);assert.equal(pole.nightState,'no-night');assert.ok(pole.rows.every(row=>row.intervals.length===0));const dark=buildObservingPlan({...context,latitude:78.2232,longitude:15.6469},'Arctic/Longyearbyen','2026-12-21');assert.equal(dark.nightState,'polar-night');assert.ok(dark.rows.some(row=>row.intervals.length));assert.equal(plan.startUtc,plan.sunsetUtc);assert.equal(plan.endUtc,plan.sunriseUtc);const jupiter=plan.rows.find(row=>row.id==='jupiter')!;assert.ok(bodyAltitude('sun',new Date(jupiter.bestInstantUtc!),new A.Observer(context.latitude,context.longitude,0))< -6);
});
test('standard Sun and Moon rise/set agree with independent frozen USNO facts at six sites/dates',()=>{
 const manifest=JSON.parse(read('../../../tests/ReferenceData/Observing/manifest.json').toString());let samples=0,max=0;
 for(const row of manifest.rows){const raw=read('../../../tests/ReferenceData/Observing/'+row.file);assert.equal(crypto.createHash('sha256').update(raw).digest('hex'),row.sha256);const data=JSON.parse(raw.toString()).properties.data,site=new A.Observer(row.latitude,row.longitude,0),start=new Date(row.date+'T00:00:00Z');
  for(const [body,key] of [[A.Body.Sun,'sundata'],[A.Body.Moon,'moondata']] as const)for(const fact of data[key])if(['Rise','Set'].includes(fact.phen)){
   const actual=A.SearchRiseSet(body,site,fact.phen==='Rise'?1:-1,start,1);assert.ok(actual);const delta=Math.abs(+actual.date-Date.parse(`${row.date}T${fact.time}:00Z`))/1000;max=Math.max(max,delta);assert.ok(delta<=manifest.toleranceSeconds,`${row.site} ${body} ${fact.phen}: ${delta}s`);samples++;
  }
 }
 assert.ok(samples>=18);console.log(`Independent standard rise/set: ${samples} facts, max ${max.toFixed(2)} s`);
});
test('all archived USNO phases and the accumulated event catalogue retain independent provenance',()=>{
 const manifest=JSON.parse(read('../../../data/events/sources.json').toString()),catalog=JSON.parse(read('../../../data/events/calendar.json').toString());let count=0;
 for(const source of manifest.sources){const raw=read('../../../'+source.file);assert.equal(crypto.createHash('sha256').update(raw).digest('hex'),source.sha256);for(const row of JSON.parse(raw.toString()).phasedata){const instant=`${row.year}-${String(row.month).padStart(2,'0')}-${String(row.day).padStart(2,'0')}T${row.time}:00.000Z`,event=catalog.events.find((e:any)=>e.instantUtc===instant&&e.sourceId==='usno');assert.ok(event);assert.ok(Math.abs(Date.parse(event.computedInstantUtc)-Date.parse(instant))<=120000);count++;}}
 assert.equal(count,1781);assert.equal(new Set(catalog.events.map((e:any)=>e.id)).size,catalog.events.length);
 const oct=calendarMonth(2026,10);assert.ok(oct.events.some(e=>e.kind==='last-quarter'&&e.instantUtc==='2026-10-03T13:25:00.000Z'));assert.ok(oct.events.some(e=>e.kind==='opposition'&&e.targetId==='saturn'));
});
test('calendar API is cacheable and local place resolution is private, bounded and language-neutral',async()=>{
 const r=calendarGET(new Request('http://localhost/api/calendar?year=2026&month=10'));assert.equal(r.status,200);assert.ok(r.headers.get('ETag'));
 assert.equal(calendarGET(new Request('http://localhost/api/calendar?year=2026&month=10',{headers:{'If-None-Match':r.headers.get('ETag')!}})).status,304);
 assert.equal(calendarGET(new Request('http://localhost/api/calendar?year=2036&month=1')).status,400);
 const found=searchPlaces('Balıkesir Altıeylül');assert.ok(found.some(p=>p.name.includes('Altıeylül')));assert.ok(searchPlaces('Sydney').length);assert.ok(nearestPlace(context.latitude,context.longitude));assert.equal(nearestPlace(0,0),null);
 const p=await placesPOST(new Request('http://localhost/api/location/places',{method:'POST',body:JSON.stringify({query:'Altıeylül'})}));assert.equal(p.status,200);assert.equal(p.headers.get('Cache-Control'),'no-store');
 assert.equal((await placesPOST(new Request('http://localhost/api/location/places',{method:'POST',body:'{"latitude":91,"longitude":0}'}))).status,400);
 assert.deepEqual(Object.keys(planningText.tr).sort(),Object.keys(planningText.en).sort());assert.deepEqual(Object.keys(planningText.tr.eventKinds).sort(),Object.keys(planningText.en.eventKinds).sort());
});
