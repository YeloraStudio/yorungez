import assert from 'node:assert/strict';
import test from 'node:test';
import {projectConstellationArt,triangleInViewport} from '../lib/sky/art.ts';
import {constellationArcs,drawConstellationLines} from '../lib/sky/constellation-lines.ts';
import {horizontalVector,projector} from '../lib/sky/projection.ts';
import type {SkyCatalog} from '../lib/sky/types.ts';

test('artwork loads on demand, fades at the edge, and fades in again without a repeat request',t=>{
 const requested:string[]=[];
 const previous=Object.getOwnPropertyDescriptor(globalThis,'Image');
 Object.defineProperty(globalThis,'Image',{configurable:true,value:class {
  complete=true;
  naturalWidth=100;
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
 const images=new Map<string,HTMLImageElement>();
 const entered=new Map<string,number>();
 function draw(azimuth:number,now:number,reduced=false){
  const camera={azimuth,altitude:0,fieldOfView:30};
  const view={width:1000,height:800,now,moving:false,reduced};
  return projectConstellationArt(catalog,vectors,projector(camera,view.width,view.height),camera,view,images,entered,()=>{});
 }
 draw(180,0);
 assert.deepEqual(draw(180,16),{meshes:[],animating:true});
 assert.deepEqual(requested,['/sky-art/south.webp']);
 const entering=draw(180,80);
 const full=draw(180,220);
 assert.ok(entering.meshes[0].opacity>0&&entering.meshes[0].opacity<full.meshes[0].opacity);
 assert.equal(full.animating,false);
 const atEdge=draw(200.7,250);
 assert.ok(atEdge.meshes[0].opacity>0&&atEdge.meshes[0].opacity<full.meshes[0].opacity);
 assert.deepEqual(draw(215,270),{meshes:[],animating:false});
 assert.equal(entered.has('south'),false);
 assert.deepEqual(draw(180,300),{meshes:[],animating:true});
 assert.equal(draw(180,300,true).meshes[0].opacity,full.meshes[0].opacity);
 draw(0,320);
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
 const segments:number[]=[],nodes:number[]=[];
 const ctx={save(){},restore(){},beginPath(){},moveTo(){},lineTo(x:number){segments.push(x);},arc(x:number){nodes.push(x);},stroke(){},fill(){}} as unknown as CanvasRenderingContext2D;
 const starts=new Map<string,number>();
 assert.equal(drawConstellationLines(ctx,arcs,project,200,100,false,null,starts,100,false),true);
 assert.deepEqual(segments,[]);
 assert.deepEqual(nodes,[project(...horizontalVector(0,0))![0],project(...horizontalVector(12,0))![0]]);
 assert.equal(drawConstellationLines(ctx,arcs,project,200,100,false,null,starts,260,false),true);
 const partial=segments.at(-1)!;
 assert.equal(drawConstellationLines(ctx,arcs,project,200,100,false,null,starts,100,true),false);
 assert.ok(segments.at(-1)!>partial);
});
