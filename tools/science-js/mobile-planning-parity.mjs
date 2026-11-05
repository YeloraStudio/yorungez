// Offline pinned-engine standard rise/set parity for the native planning ABI.
import * as A from 'astronomy-engine';
const cases = [
  ['istanbul',41.0082,28.9784,'2026-11-05T09:00:00Z','2026-11-06T09:00:00Z'],
  ['kathmandu',27.7172,85.324,'2026-11-05T06:15:00Z','2026-11-06T06:15:00Z'],
  ['sydney',-33.8688,151.2093,'2026-06-21T02:00:00Z','2026-06-22T02:00:00Z'],
  ['polar-day',78.2232,15.6469,'2026-06-21T10:00:00Z','2026-06-22T10:00:00Z'],
  ['polar-night',78.2232,15.6469,'2026-12-21T11:00:00Z','2026-12-22T11:00:00Z'],
  ['dst-short',40.7128,-74.006,'2026-03-07T17:00:00Z','2026-03-08T16:00:00Z'],
  ['dst-long',40.7128,-74.006,'2026-10-31T16:00:00Z','2026-11-01T17:00:00Z'],
  ['date-line',21.3069,-157.8583,'2026-11-05T22:00:00Z','2026-11-06T22:00:00Z'],
];
const bodies=[A.Body.Sun,A.Body.Moon,A.Body.Mercury,A.Body.Venus,A.Body.Mars,A.Body.Jupiter,A.Body.Saturn,A.Body.Uranus,A.Body.Neptune];
const rows=[];
for(const [id,latitude,longitude,startUtc,endUtc] of cases){
 const site=new A.Observer(latitude,longitude,0),start=new Date(startUtc),end=new Date(endUtc);
 for(let index=0;index<9;index++){
  const edges=[];
  for(const direction of [1,-1]){
   let cursor=start;
   for(let n=0;n<4;n++){
    const t=A.SearchRiseSet(bodies[index],site,direction,cursor,(+end-+cursor)/86400000);
    if(!t||t.date>=end)break;
    edges.push([+t.date/1000,direction===1?1:0]);cursor=new Date(+t.date+1000);
   }
  }
  edges.sort((a,b)=>a[0]-b[0]);
  rows.push({id,latitude,longitude,startUtc,endUtc,index,edges});
 }
}
process.stdout.write(JSON.stringify(rows));
