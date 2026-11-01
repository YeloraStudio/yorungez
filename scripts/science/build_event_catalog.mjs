import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import {fileURLToPath} from 'node:url';
import * as A from '../../src/Yorungez.Web/node_modules/astronomy-engine/astronomy.js';
if(!process.argv.includes('--refresh'))throw new Error('Explicit --refresh required. Normal builds read the frozen catalogue.');
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../..'),dir=path.join(root,'data/events');
const source=JSON.parse(fs.readFileSync(path.join(dir,'sources.json'))),events=[],checks=[];
const kinds={'New Moon':['new-moon',0],'First Quarter':['first-quarter',1],'Full Moon':['full-moon',2],'Last Quarter':['last-quarter',3]};
function add(kind,body,date,sourceId,extra={}){const instantUtc=date.toISOString();events.push({id:`${kind}-${body}-${instantUtc.slice(0,16)}`,kind,targetId:body,instantUtc,sourceId,...extra});}
for(const s of source.sources){
 const bytes=fs.readFileSync(path.join(root,s.file));if(crypto.createHash('sha256').update(bytes).digest('hex')!==s.sha256)throw new Error('USNO hash mismatch');
 const year=s.year,start=new Date(Date.UTC(year,0,1)),end=new Date(Date.UTC(year+1,0,1));
 for(const row of JSON.parse(bytes).phasedata){
  const [kind,quarter]=kinds[row.phase],time=new Date(`${row.year}-${String(row.month).padStart(2,'0')}-${String(row.day).padStart(2,'0')}T${row.time}:00Z`);
  const computed=A.SearchMoonPhase(quarter*90,new Date(+time-86400000),2);if(!computed)throw new Error('Missing phase root');
  const delta=Math.abs(+computed.date-time)/1000;checks.push({kind,instantUtc:time.toISOString(),deltaSeconds:delta});if(delta>120)throw new Error(`Phase discrepancy ${year} ${delta}s`);
  add(kind,'moon',time,'usno',{computedInstantUtc:computed.date.toISOString(),referenceDeltaSeconds:delta});
 }
 for(const [field,kind] of [['mar_equinox','march-equinox'],['jun_solstice','june-solstice'],['sep_equinox','september-equinox'],['dec_solstice','december-solstice']])add(kind,'sun',A.Seasons(year)[field].date,'astronomy-engine');
 for(const body of ['Mars','Jupiter','Saturn','Uranus','Neptune']){
  let cursor=start;for(let n=0;n<5;n++){const t=A.SearchRelativeLongitude(A.Body[body],0,cursor);if(t.date>=end)break;add('opposition',body.toLowerCase(),t.date,'astronomy-engine');cursor=new Date(+t.date+10*86400000);}
 }
 for(const body of ['Mercury','Venus']){
  for(const [angle,kind] of [[0,'inferior-conjunction'],[180,'superior-conjunction']]){let cursor=start;for(let n=0;n<8;n++){const t=A.SearchRelativeLongitude(A.Body[body],angle,cursor);if(t.date>=end)break;add(kind,body.toLowerCase(),t.date,'astronomy-engine');cursor=new Date(+t.date+10*86400000);}}
  let cursor=start;for(let n=0;n<10;n++){const t=A.SearchMaxElongation(A.Body[body],cursor);if(t.time.date>=end)break;add('greatest-elongation',body.toLowerCase(),t.time.date,'astronomy-engine',{elongationDegrees:t.elongation,visibility:t.visibility});cursor=new Date(+t.time.date+10*86400000);}
 }
}
events.sort((a,b)=>a.instantUtc.localeCompare(b.instantUtc));if(new Set(events.map(e=>e.id)).size!==events.length)throw new Error('Duplicate event');
const data=JSON.stringify({schemaVersion:1,startYear:2000,endYear:2035,events})+'\n',hash=crypto.createHash('sha256').update(data).digest('hex');
fs.writeFileSync(path.join(dir,'calendar.json'),data);
fs.writeFileSync(path.join(dir,'manifest.json'),JSON.stringify({schemaVersion:1,sha256:hash,eventCount:events.length,source:'USNO phase facts + Astronomy Engine 2.1.19 calculated seasons/planet events',phaseReferenceCount:checks.length,maxPhaseDifferenceSeconds:Math.max(...checks.map(c=>c.deltaSeconds)),toleranceSeconds:120,engineVersion:'2.1.19',generatedAtUtc:new Date().toISOString(),sources:[{id:'usno',url:'https://aa.usno.navy.mil/data/MoonPhases'},{id:'astronomy-engine',url:'https://github.com/cosinekitty/astronomy/tree/v2.1.19'}]},null,2)+'\n');
fs.writeFileSync(path.join(root,'docs/science/calendar-reference-report.json'),JSON.stringify({samples:checks.length,maxDifferenceSeconds:Math.max(...checks.map(c=>c.deltaSeconds)),toleranceSeconds:120,scope:'Global primary lunar phases only; independent USNO minute precision, UT treated as UTC. Other calculated event timing not independently certified.',checks},null,2)+'\n');
console.log(`Built ${events.length} events; ${checks.length} USNO phase checks, max ${Math.max(...checks.map(c=>c.deltaSeconds)).toFixed(2)} s.`);
