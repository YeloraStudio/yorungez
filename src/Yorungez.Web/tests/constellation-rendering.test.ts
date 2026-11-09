import assert from 'node:assert/strict';
import test from 'node:test';
import {drawConstellationArt,triangleInViewport} from '../lib/sky/art.ts';
import {constellationArcs,drawConstellationLines} from '../lib/sky/constellation-lines.ts';
import {horizontalVector,projector} from '../lib/sky/projection.ts';
import type {SkyCatalog} from '../lib/sky/types.ts';

test('artwork requests follow the visible mesh in CSS pixels and are reused',t=>{
 const requested:string[]=[];
 const previous=Object.getOwnPropertyDescriptor(globalThis,'Image');
 Object.defineProperty(globalThis,'Image',{configurable:true,value:class {
  complete=false;
  set src(value:string){requested.push(value);}
 }});
 t.after(()=>{
  if(previous)Object.defineProperty(globalThis,'Image',previous);
  else Reflect.deleteProperty(globalThis,'Image');
 });
 const baseStar={id:'test',raHoursJ2000:0,decDegreesJ2000:0,positionPc:[0,0,0] as [number,number,number],velocityPcPerYear:[0,0,0] as [number,number,number]};
 const anchors=[0,1].flatMap(()=>[{x:0,y:0},{x:100,y:0},{x:0,y:100}]).map(anchor=>({...anchor,star:baseStar}));
 const catalog:SkyCatalog={schemaVersion:1,version:'test',epoch:'J2000',stars:[],constellations:[],art:{anchors,figures:[
  {id:'south',src:'/sky-art/south.webp',size:[100,100],anchors:[0,1,2]},
  {id:'north',src:'/sky-art/north.webp',size:[100,100],anchors:[3,4,5]},
 ]}};
 const vectors=new Float64Array([180,0].flatMap(az=>[
  horizontalVector(az-6,6),horizontalVector(az+6,6),horizontalVector(az-6,-6)
 ].flat()));
 const ctx={canvas:{width:2000,height:1600},save(){},restore(){}} as unknown as CanvasRenderingContext2D;
 const images=new Map<string,HTMLImageElement>();
 function draw(azimuth:number){
  const camera={azimuth,altitude:0,fieldOfView:30};
  drawConstellationArt(ctx,catalog,vectors,projector(camera,1000,800),camera,1000,800,images,()=>{});
 }
 draw(180);draw(180);
 assert.deepEqual(requested,['/sky-art/south.webp']);
 draw(0);
 assert.deepEqual(requested,['/sky-art/south.webp','/sky-art/north.webp']);
});

test('art mesh intersection rejects triangles outside a corner and retains crossing triangles',()=>{
 assert.equal(triangleInViewport([9,13],[13,9],[13,13],10,10),false);
 assert.equal(triangleInViewport([-2,3],[12,3],[5,12],10,10),true);
 assert.equal(triangleInViewport([1,1],[2,2],[3,3],10,10),false);
});

test('visible constellation lines reveal from the first star and respect reduced motion',()=>{
 const vector=new Float64Array([...horizontalVector(0,0),...horizontalVector(12,0)]);
 const arcs=constellationArcs([{id:'con-test',iau:'Test',names:{en:'Test',tr:'Test'},lines:[['start','end']]}],new Map([['start',0],['end',1]]),vector);
 const project=projector({azimuth:6,altitude:0,fieldOfView:45},200,100);
 const segments:number[]=[];
 const ctx={save(){},restore(){},beginPath(){segments.length=0;},moveTo(){},lineTo(x:number){segments.push(x);},stroke(){}} as unknown as CanvasRenderingContext2D;
 const starts=new Map<string,number>();
 assert.equal(drawConstellationLines(ctx,arcs,project,200,100,false,null,starts,100,false),true);
 assert.deepEqual(segments,[]);
 assert.equal(drawConstellationLines(ctx,arcs,project,200,100,false,null,starts,260,false),true);
 const partial=segments.at(-1)!;
 assert.equal(drawConstellationLines(ctx,arcs,project,200,100,false,null,starts,100,true),false);
 assert.ok(segments.at(-1)!>partial);
});
