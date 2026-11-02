import assert from 'node:assert/strict';
import test from 'node:test';
import fs from 'node:fs';
import crypto from 'node:crypto';
import {sampleStatus,sensorAccess,safePermissionError} from '../lib/location/compass-access.ts';
import {findObjects,objectSearchEntry} from '../lib/sky/object-search.ts';
test('motion-sensor introspection distinguishes blocked, granted, prompt and unsupported states without inventing access',async()=>{
 const permissions=await sensorAccess(async name=>{if(name==='gyroscope')throw new TypeError('not queryable');return {state:name==='magnetometer'?'denied':'granted'}});
 assert.deepEqual(permissions,{accelerometer:'granted',gyroscope:'unknown',magnetometer:'denied'});
 assert.ok(Object.values(await sensorAccess(undefined)).every(v=>v==='unknown'));
 assert.ok(Object.values(await sensorAccess(async()=>({state:'prompt'}))).every(v=>v==='prompt'));
 const error=new Error('Private URL or device information must not be retained');error.name='NotAllowedError';assert.equal(safePermissionError(error),'NotAllowedError');
 assert.equal(safePermissionError('private details'),'Error');
});
test('compass diagnostic classifications preserve absolute heading and flat-phone requirements',()=>{
 assert.equal(sampleStatus({absolute:true,alpha:90,beta:0,gamma:0},0),'usable');
 assert.equal(sampleStatus({alpha:90,beta:0,gamma:0},0),'relative');
 assert.equal(sampleStatus({absolute:true,alpha:90,beta:70,gamma:0},0),'tilted');
 assert.equal(sampleStatus({absolute:true,alpha:null,beta:0,gamma:0},0),'invalid');
 assert.equal(sampleStatus({alpha:null,beta:null,gamma:null},0),'invalid');
});
test('Milky Way aliases in both languages resolve to an extended feature with honest regional navigation and a verified real panorama',()=>{
 const {milkyWay:f}=JSON.parse(fs.readFileSync(new URL('../../../data/catalog/sky-features.json',import.meta.url),'utf8'));
 const row=objectSearchEntry(f.id,f.aliases);
 for(const query of ['Milky Way','milkyway','Samanyolu','Samanyolu Galaksisi','Saman yolu'])assert.equal(findObjects([row],query)[0],f.id);
 assert.equal(f.region.id,'con-sgr');assert.ok(!('raHoursJ2000' in f));assert.ok(!('decDegreesJ2000' in f));
 const catalog=JSON.parse(fs.readFileSync(new URL('../../../data/catalog/bright-sky.json',import.meta.url),'utf8'));
 assert.ok(catalog.constellations.some((c:any)=>c.id===f.region.id));
 const photo=fs.readFileSync(new URL('../public'+f.image.url,import.meta.url));assert.equal(photo.length,f.image.bytes);assert.equal(crypto.createHash('sha256').update(photo).digest('hex'),f.image.sha256);assert.equal(f.image.credit,'ESO/S. Brunier');assert.equal(f.image.license,'CC BY 4.0');
 for(const lang of ['en','tr'])assert.ok(f.description[lang]&&f.region[lang]&&f.names[lang]);
});
