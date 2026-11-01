import * as A from 'astronomy-engine';
import {Temporal} from '@js-temporal/polyfill';
import type {ObserverContext} from './types.ts';
export const PLAN_IDS=['moon','mercury','venus','mars','jupiter','saturn','uranus','neptune'] as const;
export interface PlanInterval {startUtc:string;endUtc:string}
export interface PlanRow {id:string;intervals:PlanInterval[];bestInstantUtc:string|null;bestAltitude:number|null;riseUtc:string|null;setUtc:string|null}
export interface ObservingPlan {date:string;zone:string;mode:'tonight';nightState:'ordinary'|'polar-night'|'no-night'|'partial';startUtc:string;endUtc:string;sunsetUtc:string|null;sunriseUtc:string|null;rows:PlanRow[];definition:string}
const body=(id:string)=>A.Body[(id[0].toUpperCase()+id.slice(1)) as keyof typeof A.Body];
export function bodyAltitude(id:string,date:Date,site:A.Observer){const eq=A.Equator(body(id),date,site,true,true);return A.Horizon(date,site,eq.ra,eq.dec,'').altitude;}
export function nightBounds(zone:string,date:string){
 const day=Temporal.PlainDate.from(date);if(day.year<2000||day.year>2035)throw new Error('unsupported-date');
 const noon=(d:Temporal.PlainDate)=>d.toZonedDateTime({timeZone:zone,plainTime:Temporal.PlainTime.from({hour:12})}).toInstant().toString();
 const startUtc=noon(day),endUtc=noon(day.add({days:1}));
 if(Date.parse(endUtc)>Date.parse('2036-01-01T00:00:00Z')||Date.parse(startUtc)<Date.parse('2000-01-01T00:00:00Z'))throw new Error('unsupported-window');
 return {startUtc,endUtc};
}
function crossings(id:string,site:A.Observer,start:Date,end:Date){
 const edges:{time:number;up:boolean}[]=[];
 for(const direction of [1,-1]){let cursor=start;for(let n=0;n<4;n++){const t=A.SearchRiseSet(body(id),site,direction,cursor,(+end-cursor.getTime())/86400000);if(!t||t.date>=end)break;edges.push({time:+t.date,up:direction===1});cursor=new Date(+t.date+1000);}}
 edges.sort((a,b)=>a.time-b.time);
 const eq=A.Equator(body(id),start,site,true,true),radiusKm=id==='sun'?695700:id==='moon'?1737.4:0;
 const upperLimb=Math.asin(radiusKm/(eq.dist*A.KM_PER_AU))*A.RAD2DEG;
 const initiallyAbove=edges.length?!edges[0].up:bodyAltitude(id,start,site)+upperLimb+34/60>0;
 return {edges,initiallyAbove};
}
function intervals(start:number,end:number,edges:{time:number;up:boolean}[],initial:boolean,above=true){
 let active=initial===above,begun=active?start:0;const result:PlanInterval[]=[];
 for(const edge of edges){const next=edge.up===above;if(next&&!active)begun=edge.time;if(!next&&active)result.push({startUtc:new Date(begun).toISOString(),endUtc:new Date(edge.time).toISOString()});active=next;}
 if(active)result.push({startUtc:new Date(begun).toISOString(),endUtc:new Date(end).toISOString()});return result;
}
export function buildObservingPlan(context:ObserverContext,zone:string,date:string):ObservingPlan{
 const bounds=nightBounds(zone,date),start=new Date(bounds.startUtc),end=new Date(bounds.endUtc);
 const site=new A.Observer(context.latitude,context.longitude,context.elevationMeters??0);
 // Map heights are ellipsoidal; no geoid conversion into rise/set atmospheric height exists yet.
 const standardSite=new A.Observer(context.latitude,context.longitude,0),sun=crossings('sun',standardSite,start,end);
 const nights=intervals(+start,+end,sun.edges,sun.initiallyAbove,false);
 const state=!nights.length?'no-night':!sun.edges.length?'polar-night':sun.edges.length<2?'partial':'ordinary';
 const rows=PLAN_IDS.map(id=>{
  const {edges,initiallyAbove}=crossings(id,standardSite,start,end),up=intervals(+start,+end,edges,initiallyAbove);
  const visible:PlanInterval[]=[];
  for(const a of up)for(const b of nights){const s=Math.max(Date.parse(a.startUtc),Date.parse(b.startUtc)),e=Math.min(Date.parse(a.endUtc),Date.parse(b.endUtc));if(e>s)visible.push({startUtc:new Date(s).toISOString(),endUtc:new Date(e).toISOString()});}
  let best:number|null=null,bestAltitude=-Infinity,bestDark=false;
  // A navigation suggestion inside the night; never an exact transit or detection certificate.
  for(const interval of visible){const a=Date.parse(interval.startUtc),b=Date.parse(interval.endUtc);for(let n=0;n<25;n++){const t=a+(b-a)*(n+.5)/25,alt=bodyAltitude(id,new Date(t),site),dark=bodyAltitude('sun',new Date(t),standardSite)< -6;if((dark&&!bestDark)||(dark===bestDark&&alt>bestAltitude)){best=t;bestAltitude=alt;bestDark=dark;}}}
  return {id,intervals:visible,bestInstantUtc:best===null?null:new Date(best).toISOString(),bestAltitude:best===null?null:bestAltitude,riseUtc:edges.find(e=>e.up)?new Date(edges.find(e=>e.up)!.time).toISOString():null,setUtc:edges.find(e=>!e.up)?new Date(edges.find(e=>!e.up)!.time).toISOString():null};
 });
 return {date,zone,mode:'tonight',nightState:state,startUtc:nights[0]?.startUtc??bounds.startUtc,endUtc:nights.at(-1)?.endUtc??bounds.endUtc,sunsetUtc:sun.edges.find(e=>!e.up)?new Date(sun.edges.find(e=>!e.up)!.time).toISOString():null,sunriseUtc:sun.edges.find(e=>e.up)?new Date(sun.edges.find(e=>e.up)!.time).toISOString():null,rows,definition:'Astronomy Engine 2.1.19 standard rise/set: sea-level 0 m reference, 34 arcmin refraction, Sun/Moon upper limb; sunset to sunrise only, no geoid conversion, terrain/weather/contrast not evaluated.'};
}
