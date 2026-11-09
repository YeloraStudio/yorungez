import assert from 'node:assert/strict';
import test from 'node:test';
import fs from 'node:fs';import crypto from 'node:crypto';
import {groundSampler,screenRay,landscapeUv,uploadPanorama} from '../lib/sky/natural-scene.ts';
import {horizontalVector,projector} from '../lib/sky/projection.ts';
import {daylight,starAppearance} from '../lib/sky/appearance.ts';
import {readHeading,HeadingSession} from '../lib/location/compass.ts';
import type {CompassState,OrientationSample} from '../lib/location/compass.ts';
import type {Camera} from '../lib/sky/types.ts';
test('natural scene uses the same sky directions, including zenith, nadir and 360 seam',()=>{
 for(const camera of [{azimuth:0,altitude:0,fieldOfView:105},{azimuth:359,altitude:28,fieldOfView:75},{azimuth:45,altitude:90,fieldOfView:40},{azimuth:12,altitude:-90,fieldOfView:100}]){
  const ray=screenRay(camera,1280,720,640,360),centre=horizontalVector(camera.azimuth,camera.altitude);for(let i=0;i<3;i++)assert.ok(Math.abs(ray[i]-centre[i])<1e-12);
  for(const [x,y] of [[0,0],[1280,720],[390,240],[640,360]]){const p=projector(camera,1280,720)(...screenRay(camera,1280,720,x,y));assert.ok(p);assert.ok(Math.hypot(p[0]-x,p[1]-y)<1e-8);}
 }
 assert.deepEqual(landscapeUv(0,90),[.25,0]);assert.deepEqual(landscapeUv(360,-90),[.25,1]);
});
test('visual exposure preserves dark nights and magnitude ordering without changing science',()=>{
 assert.equal(daylight(-18),0);assert.equal(daylight(20),1);assert.ok(daylight(-6)>daylight(-12));
 assert.ok(starAppearance(-1).radius>starAppearance(1).radius);assert.ok(starAppearance(1).radius>starAppearance(6).radius);
});
test('fast fallback terrain agrees with the full inverse projection',()=>{
 const views:Camera[]=[
  {azimuth:350,altitude:14,fieldOfView:105},
  {azimuth:5,altitude:-90,fieldOfView:330},
  {azimuth:45,altitude:90,fieldOfView:330},
  {azimuth:180,altitude:-7,roll:120,fieldOfView:60,projection:'perspective'},
 ];
 for(const camera of views){
  const below=groundSampler(camera,1280,720);
  for(let y=4;y<720;y+=16)for(let x=4;x<1280;x+=16){
   assert.equal(below(x,y),screenRay(camera,1280,720,x,y)[2]<0);
  }
 }
});
test('panorama is an unchanged, attributed photograph verified without downloads',()=>{
 const m=JSON.parse(fs.readFileSync(new URL('../../../data/catalog/landscape-manifest.json',import.meta.url),'utf8'));
 const bytes=fs.readFileSync(new URL('../../../'+m.file,import.meta.url));assert.equal(crypto.createHash('sha256').update(bytes).digest('hex'),m.sha256);assert.equal(bytes.readUInt32BE(16),4096);assert.ok(m.author&&m.licenseUrl&&m.sourceUrl);
});

test('panorama preserves native 4K detail without upscaling or exceeding the GPU limit',()=>{
 const attempted:number[]=[];const upload=(width:number)=>{attempted.push(width);return true};
 assert.equal(uploadPanorama(4096,8192,upload),4096);assert.deepEqual(attempted,[4096]);attempted.length=0;
 assert.equal(uploadPanorama(4096,2048,upload),2048);assert.deepEqual(attempted,[2048]);attempted.length=0;
 assert.equal(uploadPanorama(2048,8192,upload),2048);assert.deepEqual(attempted,[2048]);
 assert.equal(uploadPanorama(4096,NaN,()=>{throw new Error('invalid capability')}),0);
});

test('a failed 4K allocation retries smaller textures and all failures keep the simplified fallback',()=>{
 const attempted:number[]=[];
 assert.equal(uploadPanorama(4096,8192,width=>{attempted.push(width);return width<=2048}),2048);
 assert.deepEqual(attempted,[4096,2048]);attempted.length=0;
 assert.equal(uploadPanorama(4096,8192,width=>{attempted.push(width);return false}),0);
 assert.deepEqual(attempted,[4096,2048,1024,512]);
});
test('relative orientation, tilted phones and bad compass accuracy cannot invent north',()=>{
 const base={alpha:90,beta:0,gamma:0};assert.equal(readHeading(base),null);assert.equal(readHeading({...base,absolute:true})?.degrees,270);
 assert.equal(readHeading({...base,absolute:true},90)?.degrees,0);assert.equal(readHeading({...base,absolute:true,beta:70}),null);
 assert.equal(readHeading({...base,webkitCompassHeading:359,webkitCompassAccuracy:5},2)?.degrees,1);
 assert.equal(readHeading({...base,webkitCompassHeading:20,webkitCompassAccuracy:-1}),null);assert.equal(readHeading({...base,webkitCompassHeading:20,webkitCompassAccuracy:45}),null);
});
test('compass permissions, stale data and disposal cannot leave an actionable old heading',async()=>{
 const states:CompassState[]=[],headings:number[]=[];let listener:((s:OrientationSample,a:number)=>void)|undefined,removed=0;
 const session=new HeadingSession({secure:true,supported:true,subscribe:cb=>{listener=cb;return()=>{removed++;listener=undefined}}},s=>states.push(s),h=>headings.push(h.degrees),20);
 await session.start();const late=listener!;late({absolute:true,alpha:0,beta:0,gamma:0},0);assert.equal(states.at(-1),'ready');
 await new Promise(r=>setTimeout(r,35));assert.equal(states.at(-1),'unavailable');assert.equal(removed,1);late({absolute:true,alpha:90,beta:0,gamma:0},0);assert.deepEqual(headings,[0]);session.stop();late({absolute:true,alpha:90,beta:0,gamma:0},0);assert.deepEqual(headings,[0]);
 const denied=new HeadingSession({secure:true,supported:true,requestPermission:async()=>'denied',subscribe:()=>{throw new Error('must not subscribe')}},s=>states.push(s),()=>{});await denied.start();assert.equal(states.at(-1),'denied');denied.stop(false);
 const unsupported=new HeadingSession({secure:true,supported:false,subscribe:()=>()=>{}},s=>states.push(s),()=>{});await unsupported.start();assert.equal(states.at(-1),'unsupported');unsupported.stop(false);
});
