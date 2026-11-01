import fs from 'node:fs';import path from 'node:path';import zlib from 'node:zlib';import crypto from 'node:crypto';
export interface Place {id:number;name:string;ascii:string;latitude:number;longitude:number;country:string;region:string;population:number;feature:string}
export interface CalendarEvent {id:string;kind:string;targetId:string;instantUtc:string;sourceId:string;computedInstantUtc?:string;referenceDeltaSeconds?:number;elongationDegrees?:number;visibility?:string}
let places:{row:Place;key:string}[]|undefined,calendar:{events:CalendarEvent[];provenance:Record<string,unknown>}|undefined;
export const normalizePlace=(s:string)=>s.normalize('NFD').replace(/[\u0300-\u036f]/g,'').replace(/ı/g,'i').toLowerCase();
function verified(file:string,manifestFile:string){const dir=path.join(process.cwd(),'generated'),data=fs.readFileSync(path.join(dir,file)),manifest=JSON.parse(fs.readFileSync(path.join(dir,manifestFile),'utf8'));if(crypto.createHash('sha256').update(data).digest('hex')!==manifest.sha256)throw new Error('catalogue-integrity');return {data,manifest};}
function placeRows(){if(!places){const {data}=verified('cities.json.gz','places-manifest.json');places=(JSON.parse(zlib.gunzipSync(data).toString()) as Place[]).map(row=>({row,key:normalizePlace(`${row.name} ${row.ascii} ${row.region} ${row.country}`)}));}return places;}
export function searchPlaces(query:string){const tokens=normalizePlace(query.trim()).split(/\s+/);if(query.trim().length<2||query.length>120)throw new Error('query');return placeRows().filter(p=>tokens.every(t=>p.key.includes(t))).sort((a,b)=>(normalizePlace(b.row.name)===tokens.join(' ')?1:0)-(normalizePlace(a.row.name)===tokens.join(' ')?1:0)||b.row.population-a.row.population).slice(0,8).map(p=>p.row);}
export function nearestPlace(latitude:number,longitude:number){if(!Number.isFinite(latitude)||Math.abs(latitude)>90||!Number.isFinite(longitude)||Math.abs(longitude)>180)throw new Error('coordinates');
 let found:Place|null=null,best=100;const r=Math.PI/180;
 for(const {row} of placeRows()){if(Math.abs(row.latitude-latitude)>.91)continue;const a=(row.latitude-latitude)*r,b=(row.longitude-longitude)*r,h=Math.sin(a/2)**2+Math.cos(latitude*r)*Math.cos(row.latitude*r)*Math.sin(b/2)**2,d=12742*Math.asin(Math.sqrt(Math.min(1,h)));if(d<best){best=d;found=row;}}
 return found?{...found,distanceKm:best}:null;
}
export function calendarMonth(year:number,month:number){if(!Number.isInteger(year)||year<2000||year>2035||!Number.isInteger(month)||month<1||month>12)throw new Error('month');
 if(!calendar){const {data,manifest}=verified('calendar.json','calendar-manifest.json');calendar={events:JSON.parse(data.toString()).events,provenance:manifest};}
 const start=Date.UTC(year,month-1,1)-2*86400000,end=Date.UTC(year,month,1)+2*86400000;
 return {year,month,events:calendar.events.filter(e=>{const t=Date.parse(e.instantUtc);return t>=start&&t<end}),provenance:calendar.provenance};
}
