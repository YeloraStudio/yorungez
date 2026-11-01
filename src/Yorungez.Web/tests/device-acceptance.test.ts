import assert from 'node:assert/strict';
import test from 'node:test';
import {HeadingSession,readHeading} from '../lib/location/compass.ts';
import type {CompassState,OrientationSample} from '../lib/location/compass.ts';
import {popupBounds} from '../lib/viewport.ts';

test('invalid sensor quality immediately revokes a previously usable heading',async()=>{
 for(const invalid of [{absolute:true,alpha:90,beta:70,gamma:0},{absolute:true,alpha:90,beta:null,gamma:0},{alpha:0,beta:0,gamma:0,webkitCompassHeading:10,webkitCompassAccuracy:45}]){
  let emit!:(sample:OrientationSample,angle:number)=>void;
  const states:CompassState[]=[];
  const session=new HeadingSession({secure:true,supported:true,subscribe:cb=>{emit=cb;return()=>{}}},s=>states.push(s),()=>{});
  try{
   await session.start();emit({absolute:true,alpha:0,beta:0,gamma:0},0);assert.equal(states.at(-1),'ready');
   emit(invalid,0);assert.equal(states.at(-1),'waiting');
   emit({absolute:true,alpha:90,beta:0,gamma:0},0);assert.equal(states.at(-1),'ready');
   emit({alpha:90,beta:0,gamma:0},0);assert.equal(states.at(-1),'ready'); // Android's relative companion is not a north reference.
  }finally{session.stop(false)}
 }
 assert.equal(readHeading({absolute:true,alpha:0,beta:0,gamma:0},NaN),null);
});

test('closing while a compass permission request is pending cannot start sensors later',async()=>{
 let answer!:(result:string)=>void,subscribed=false;
 const session=new HeadingSession({secure:true,supported:true,requestPermission:()=>new Promise(resolve=>answer=resolve),subscribe:()=>{subscribed=true;return()=>{}}},()=>{},()=>{});
 const pending=session.start();session.stop(false);answer('granted');await pending;assert.equal(subscribed,false);
});

test('custom pickers remain inside narrow, landscape, zoomed and keyboard-visible bounds',()=>{
 for(const viewport of [{left:0,top:0,width:320,height:568},{left:0,top:0,width:780,height:360},{left:0,top:170,width:360,height:180},{left:40,top:90,width:180,height:240}]){
  for(const anchor of [{left:-30,top:10,bottom:54},{left:280,top:510,bottom:554},{left:60,top:200,bottom:244}]){
   const bounds=popupBounds(anchor,viewport,320,500);
   assert.ok(bounds.left>=viewport.left&&bounds.top>=viewport.top);
   assert.ok(bounds.left+bounds.width<=viewport.left+viewport.width);
   assert.ok(bounds.top+Math.min(500,bounds.maxHeight)<=viewport.top+viewport.height);
  }
 }
});
