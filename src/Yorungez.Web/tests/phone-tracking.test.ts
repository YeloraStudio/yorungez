import assert from 'node:assert/strict';import test from 'node:test';
import {rearCameraPose,PointingSession,type PhonePose,type PointingState} from '../lib/location/pointing.ts';
import type {OrientationSample} from '../lib/location/compass.ts';
import {RearCameraSession,verifiedRearCamera} from '../lib/location/rear-camera.ts';
import {projector,normalizedCamera,horizontalVector} from '../lib/sky/projection.ts';
import {screenRay} from '../lib/sky/natural-scene.ts';
const close=(a:number,b:number)=>assert.ok(Math.abs(a-b)<1e-8,`${a} != ${b}`);
const base={alpha:0,beta:90,gamma:0,absolute:true};
test('rear optical axis follows W3C cardinal examples, tilt and screen rotation',()=>{
 for(const [alpha,az] of [[0,0],[270,90],[180,180],[90,270]]){const p=rearCameraPose({...base,alpha})!;close(p.azimuth,az);close(p.altitude,0);close(p.roll,0)}
 close(rearCameraPose({...base,beta:120})!.altitude,30);
 close(rearCameraPose({...base,beta:60})!.altitude,-30);
 close(rearCameraPose({...base,gamma:30})!.azimuth,330);
 close(rearCameraPose(base,90)!.roll,90);close(rearCameraPose(base,270)!.roll,-90);
 for(const e of [{...base,alpha:null},{...base,beta:NaN},{...base,gamma:91},{...base,webkitCompassAccuracy:-1},{...base,webkitCompassAccuracy:45}])assert.equal(rearCameraPose(e),null);
 assert.equal(rearCameraPose({...base,absolute:false})!.reference,'relative');
 for(const beta of [0,180])assert.ok(Object.values(rearCameraPose({...base,beta})!).every(v=>typeof v!=='number'||Number.isFinite(v)));
});
test('projection/inverse preserve roll and perspective in portrait, landscape and at poles',()=>{
 for(const projection of [undefined,'perspective'] as const)for(const roll of [-179,-90,0,35,90,179])for(const altitude of [-90,-25,0,85,90])for(const [width,height] of [[390,844],[844,390]]){
  const camera=normalizedCamera({azimuth:359,altitude,fieldOfView:60,roll,projection});
  for(const [x,y] of [[0,0],[width,height],[width/2,height/2],[width*.3,height*.6]]){
   const point=projector(camera,width,height)(...screenRay(camera,width,height,x,y));assert.ok(point);close(point[0],x);close(point[1],y);
  }
 }
 assert.equal(projector({azimuth:0,altitude:0,fieldOfView:60,projection:'perspective'},400,800)(...horizontalVector(180,0)),null);
 assert.equal(normalizedCamera({azimuth:0,altitude:0,fieldOfView:250,projection:'perspective'}).fieldOfView,120);
});
test('projected rear optical axis and physical screen up match independently composed Z-X-Y rotations',()=>{
 const rad=Math.PI/180;
 const rotate=(v:number[],a:number,b:number,g:number)=>{
  const y=[v[0]*Math.cos(g)+v[2]*Math.sin(g),v[1],-v[0]*Math.sin(g)+v[2]*Math.cos(g)];
  const x=[y[0],y[1]*Math.cos(b)-y[2]*Math.sin(b),y[1]*Math.sin(b)+y[2]*Math.cos(b)];
  return [x[0]*Math.cos(a)-x[1]*Math.sin(a),x[0]*Math.sin(a)+x[1]*Math.cos(a),x[2]] as [number,number,number];
 };
 for(const alpha of [0,42,137,359])for(const beta of [-170,-75,1,90,120,179])for(const gamma of [-80,0,40,85])for(const angle of [0,90,180,270]){
  const p=rearCameraPose({alpha,beta,gamma,absolute:true},angle)!;
  const forward=rotate([0,0,-1],alpha*rad,beta*rad,gamma*rad);
  const up=rotate([Math.sin(angle*rad),Math.cos(angle*rad),0],alpha*rad,beta*rad,gamma*rad);
  const project=projector({...p,fieldOfView:60},400,800),centre=project(...forward)!;close(centre[0],200);close(centre[1],400);
  const point=project(...forward.map((v,i)=>v+up[i]*.1) as [number,number,number])!;
  close(point[0],200);assert.ok(point[1]<400);
 }
});
test('missing support or permission denial never subscribes to sensors',async()=>{
 for(const [secure,supported,permission,expected] of [[false,true,'granted','insecure'],[true,false,'granted','unsupported'],[true,true,'denied','denied']] as const){
  const states:PointingState[]=[];let opened=false;
  const session=new PointingSession({secure,supported,requestPermission:async()=>permission,subscribe:()=>{opened=true;return()=>{}}},s=>states.push(s),()=>{},()=>{});
  await session.start();assert.equal(states.at(-1),expected);assert.equal(opened,false);session.stop(false);
 }
});
test('relative samples require explicit calibration; absolute source change revokes it and companions cannot hijack it',async()=>{
 let emit!:(e:OrientationSample,angle:number)=>void;const states:PointingState[]=[],applied:PhonePose[]=[];
 const session=new PointingSession({secure:true,supported:true,subscribe:cb=>{emit=cb;return()=>{}}},s=>states.push(s),()=>{},p=>applied.push(p));
 try{
  await session.start();emit({...base,absolute:false},0);assert.equal(states.at(-1),'align');assert.equal(applied.length,0);
  assert.equal(session.align(90,0),true);close(applied.at(-1)!.azimuth,90);
  emit({...base,absolute:false,alpha:359},0);close(applied.at(-1)!.azimuth,91);
  emit(base,0);assert.equal(states.at(-1),'align');assert.equal(applied.length,2);
  session.align(0,0);emit({...base,absolute:false,alpha:180},0);assert.equal(applied.length,3);
  emit({...base,alpha:359},0);close(applied.at(-1)!.azimuth,1);
  emit({...base,beta:null},0);assert.equal(states.at(-1),'waiting');assert.equal(session.align(0,0),false);
  emit(base,0);assert.equal(states.at(-1),'align');assert.equal(applied.length,4);
  assert.equal(session.align(0,50),false);
 }finally{session.stop(false)}
});
test('stale readings and permission cancellation release listeners and cannot move the map later',async()=>{
 let emit!:(e:OrientationSample,angle:number)=>void,removed=0;const states:PointingState[]=[],applied:PhonePose[]=[];
 const session=new PointingSession({secure:true,supported:true,subscribe:cb=>{emit=cb;return()=>{removed++}}},s=>states.push(s),()=>{},p=>applied.push(p),20);
 await session.start();emit(base,0);session.align(0,0);await new Promise(r=>setTimeout(r,40));assert.equal(states.at(-1),'unavailable');assert.equal(removed,1);
 emit({...base,alpha:90},0);assert.equal(applied.length,1);session.stop(false);
 let answer!:(s:string)=>void,subscribed=false;
 const pending=new PointingSession({secure:true,supported:true,requestPermission:()=>new Promise(r=>answer=r),subscribe:()=>{subscribed=true;return()=>{}}},()=>{},()=>{},()=>{});
 const start=pending.start();pending.stop();answer('granted');await start;assert.equal(subscribed,false);
});
test('camera cancellation releases late streams and normal stop releases every track without recording',async()=>{
 let resolve!:(s:{getTracks:()=>{stop:()=>void}[]})=>void,stopped=0;const displayed:unknown[]=[];
 const stream={getTracks:()=>[{stop:()=>{stopped++}}]};
 const session=new RearCameraSession(()=>new Promise<typeof stream>(r=>resolve=r),s=>displayed.push(s),()=>{});
 const pending=session.start();session.stop();resolve(stream);await pending;assert.equal(stopped,1);assert.equal(displayed.some(s=>s!==null),false);
 const ready=new RearCameraSession(async()=>stream,s=>displayed.push(s),()=>{});await ready.start();assert.equal(displayed.at(-1),stream);ready.stop();assert.equal(stopped,2);
});
test('a front or unverifiable camera is released before display; verified rear camera is retained',()=>{
 for(const mode of ['user',undefined]){let stopped=0;const stream={getTracks:()=>[{stop:()=>stopped++}],getVideoTracks:()=>[{getSettings:()=>({facingMode:mode})}]};
  assert.throws(()=>verifiedRearCamera(stream));assert.equal(stopped,1);
 }
 const rear={getTracks:()=>[{stop:()=>{throw new Error('must remain active')}}],getVideoTracks:()=>[{getSettings:()=>({facingMode:'environment'})}]};assert.equal(verifiedRearCamera(rear),rear);
});
