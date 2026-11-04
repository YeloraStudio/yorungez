// Frozen numeric cases, pinned JS dependency, no network or benchmark claims.
import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import * as A from 'astronomy-engine';
const data=JSON.parse(fs.readFileSync(fileURLToPath(new URL('../../tests/ReferenceData/Horizons/references.json',import.meta.url)),'utf8'));
const points=[];
for(const c of [...data.positions,...data.events]) {
  if(Math.abs(c.latitude)>=89)continue;
  const observer=new A.Observer(c.latitude,c.longitude,c.elevationMeters??0);
  const body=A.Body[c.body[0].toUpperCase()+c.body.slice(1)];
  for(const row of c.rows) {
    const time=new Date(row.instantUtc),eq=A.Equator(body,time,observer,true,true);
    const h=A.Horizon(time,observer,eq.ra,eq.dec,'');
    points.push({id:c.id,instantUtc:row.instantUtc,azimuth:h.azimuth,altitude:h.altitude});
  }
}
process.stdout.write(JSON.stringify(points));
