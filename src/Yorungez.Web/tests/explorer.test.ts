import assert from "node:assert/strict";
import test from "node:test";
import fs from "node:fs";
import crypto from "node:crypto";
import { localToUtc,localInput,timeDraft } from "../lib/location/time.ts";
import { positionContext } from "../lib/location/position.ts";
import { SkyWorkerClient } from "../lib/sky/worker-client.ts";
import type { WorkerPort } from "../lib/sky/worker-client.ts";
import { defaultLayers } from "../lib/sky/layers.ts";
import { loadSkyCatalog } from "../lib/sky/load-catalog.ts";
import { buildFrame } from "../lib/sky/frame.ts";
import { separationArcminutes } from "../lib/sky/star-math.ts";
import { equatorialVector,horizontalVector } from "../lib/sky/projection.ts";
import type { SkyCatalog,ObserverContext } from "../lib/sky/types.ts";
import type { SkyFrame } from "../lib/sky/frame-contract.ts";
import { explorerText } from "../lib/explorer-text.ts";
import { POST } from "../app/api/location/time-zone/route.ts";
const read=(name:string)=>fs.readFileSync(new URL(name,import.meta.url));
const raw=read("../../../data/catalog/overlays.json"),overlays=JSON.parse(raw.toString());
const catalog:SkyCatalog={schemaVersion:1,version:"test",epoch:"J2000",stars:[],constellations:[],...overlays};
const context:ObserverContext={latitude:39.6484,longitude:27.8826,elevationMeters:null,instantUtc:"2026-10-31T11:24:00Z"};
class Port implements WorkerPort{onmessage:WorkerPort["onmessage"]=null;onerror:WorkerPort["onerror"]=null;sent:any[]=[];terminated=false;postMessage(x:unknown){this.sent.push(x)}terminate(){this.terminated=true}message(data:unknown){this.onmessage?.({data} as MessageEvent)}}
test("default layers exactly match the requested three; extended copy keys remain bilingual",()=>{
 assert.deepEqual(Object.entries(defaultLayers).filter(([,v])=>v).map(([k])=>k),["atmosphere","landscape","deepSky"]);
 assert.deepEqual(Object.keys(explorerText.tr).sort(),Object.keys(explorerText.en).sort());
 assert.deepEqual(Object.keys(explorerText.tr.dsoTypes).sort(),Object.keys(explorerText.en.dsoTypes).sort());
});
test("Balikesir 14:24 and 11:24 UTC are the same instant, independent of UI language",()=>{
 assert.equal(localToUtc("2026-10-31T14:24","Europe/Istanbul"),context.instantUtc);
 assert.equal(localInput(context.instantUtc,"Europe/Istanbul"),"2026-10-31T14:24");
 assert.deepEqual(timeDraft(context.instantUtc,"Europe/Istanbul",false),{basis:"UTC",value:"2026-10-31T11:24"});
 assert.deepEqual(timeDraft(context.instantUtc,"Europe/Istanbul",true),{basis:"local",value:"2026-10-31T14:24"});
 assert.equal(localToUtc("2026-10-31T17:09","Asia/Kathmandu"),context.instantUtc);
 assert.equal(localToUtc("2026-11-01T00:24","Pacific/Auckland"),context.instantUtc);
});
test("DST gaps are rejected even with an occurrence; repeated local times require an explicit choice",()=>{
 assert.throws(()=>localToUtc("2026-03-08T02:30","America/New_York"));
 assert.throws(()=>localToUtc("2026-03-08T02:30","America/New_York","later"));
 assert.throws(()=>localToUtc("2026-11-01T01:30","America/New_York"));
 assert.equal(localToUtc("2026-11-01T01:30","America/New_York","earlier"),"2026-11-01T05:30:00Z");
 assert.equal(localToUtc("2026-11-01T01:30","America/New_York","later"),"2026-11-01T06:30:00Z");
});
test("device uncertainty and timestamp survive without inventing geoid height or rounding coordinates",()=>{
 const position={timestamp:Date.parse(context.instantUtc),coords:{latitude:39.648412345678,longitude:27.882612345678,accuracy:14.6,altitude:123,altitudeAccuracy:null,heading:null,speed:null,toJSON(){return {}}}};
 const next=positionContext(position,context);assert.equal(next.latitude,position.coords.latitude);assert.equal(next.longitude,position.coords.longitude);assert.equal(next.accuracyMeters,14.6);assert.equal(next.measuredAtUtc,context.instantUtc.replace("Z",".000Z"));assert.equal(next.elevationMeters,null);assert.equal(next.source,"device");
 assert.throws(()=>positionContext({...position,coords:{...position.coords,latitude:91}},context));
});
test("cold-worker handshake keeps one running job and only the latest pending context",()=>{
 const port=new Port(),received:number[]=[];const runner=new SkyWorkerClient(catalog,f=>received.push(f.sequence),()=>{},()=>port);
 runner.request(context);runner.request({...context,longitude:1});assert.equal(port.sent.length,1);port.message({type:"ready"});assert.equal(port.sent[1].sequence,2);
 runner.request({...context,longitude:2});runner.request({...context,longitude:3});assert.equal(port.sent.length,2);
 port.message({type:"frame",frame:{sequence:2}});assert.deepEqual(received,[]);assert.equal(port.sent[2].sequence,4);
 port.message({type:"frame",frame:{sequence:4}});assert.deepEqual(received,[4]);assert.equal(runner.busy,false);runner.dispose();port.message({type:"frame",frame:{sequence:4}});assert.deepEqual(received,[4]);
});
test("a worker that never becomes ready falls back to the same real calculation instead of spinning forever",async()=>{
 const port=new Port();let runner:SkyWorkerClient;
 const result=await new Promise<SkyFrame>((resolve,reject)=>{const deadline=setTimeout(()=>reject(new Error("fallback did not recover")),2000);
  runner=new SkyWorkerClient(catalog,f=>{clearTimeout(deadline);resolve(f)},()=>{},()=>port,50);runner.request(context);
 });runner!.dispose();assert.equal(port.terminated,true);assert.equal(result.context.latitude,context.latitude);assert.ok(result.angles.every(Number.isFinite));
});
test("catalogue loading rejects malformed data and honors a deadline on a stalled connection",async()=>{
 const fake=async()=>Response.json({catalog:{stars:[]},glossary:[]});await assert.rejects(()=>loadSkyCatalog(new AbortController().signal,fake as typeof fetch,20));
 const hold=setTimeout(()=>{},100);
 try{const stalled:typeof fetch=async(_url,init)=>new Promise((_resolve,reject)=>{init!.signal!.addEventListener("abort",()=>reject(init!.signal!.reason))});await assert.rejects(()=>loadSkyCatalog(new AbortController().signal,stalled,10));}finally{clearTimeout(hold)}
});
test("new catalogue and all unmodified illustrations match their provenance; Sun snapshots have usable rights",()=>{
 const manifest=JSON.parse(read("../../../data/catalog/overlays-manifest.json").toString());assert.equal(crypto.createHash("sha256").update(raw).digest("hex"),manifest.sha256);assert.equal(overlays.deepSky.length,107);assert.equal(overlays.art.figures.length,85);
 for(const asset of manifest.artFiles)assert.equal(crypto.createHash("sha256").update(read("../../../"+asset.file)).digest("hex"),asset.sha256);
 const sun=JSON.parse(read("../../../data/catalog/sun-content.json").toString());for(const language of ["tr","en"]){assert.ok(sun[language].extract&&sun[language].revision&&sun[language].image.credit&&sun[language].image.licenseUrl);assert.equal(crypto.createHash("sha256").update(read("../public"+sun[language].image.url)).digest("hex"),sun[language].image.sha256)}
});
test("all 72 independent DSO samples meet the trial target and the equatorial grid agrees with their vectors",()=>{
 const refs=JSON.parse(read("../../../tests/ReferenceData/DeepSky/astropy.json").toString());assert.equal(refs.overlaySha256,crypto.createHash("sha256").update(raw).digest("hex"));
 let maximum=0;
 for(const row of refs.rows){const frame=buildFrame(catalog,row.context,1),index=9+catalog.deepSky!.findIndex(o=>o.id===row.id),o=catalog.deepSky![index-9];const error=separationArcminutes(frame.angles[index*2],frame.angles[index*2+1],row.azimuthDegrees,row.altitudeDegrees);maximum=Math.max(maximum,error);assert.ok(error<=1,`${row.id}: ${error}`);const grid=equatorialVector(frame.equatorialToEnu,o.raHoursJ2000,o.decDegreesJ2000),vector=horizontalVector(frame.angles[index*2],frame.angles[index*2+1]);for(let i=0;i<3;i++)assert.ok(Math.abs(grid[i]-vector[i])<1e-12);}
 assert.ok(maximum>0);
});
test("time-zone endpoint uses local polygons, keeps coordinate requests private and validates bounded bodies",async()=>{
 for(const [lat,lon,expected] of [[39.6484,27.8826,"Europe/Istanbul"],[-33.8688,151.2093,"Australia/Sydney"],[27.7172,85.324,"Asia/Kathmandu"],[52.3676,4.9041,"Europe/Amsterdam"]] as const){const r=await POST(new Request("http://localhost/api/location/time-zone",{method:"POST",body:JSON.stringify({latitude:lat,longitude:lon})}));assert.equal(r.status,200);assert.equal(r.headers.get("Cache-Control"),"no-store");assert.ok((await r.json()).zones.includes(expected));}
 for(const body of [JSON.stringify({latitude:91,longitude:0}),"x".repeat(3000)])assert.equal((await POST(new Request("http://localhost/api/location/time-zone",{method:"POST",body}))).status,400);
});
