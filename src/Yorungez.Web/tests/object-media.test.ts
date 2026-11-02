import assert from 'node:assert/strict';
import test from 'node:test';
import fs from 'node:fs';
import crypto from 'node:crypto';
import {commonsImage,messierArticleTitle} from '../lib/object-media.ts';
import {finderField} from '../lib/sky/finder-field.ts';
import {findObjects,objectSearchEntry} from '../lib/sky/object-search.ts';
import type {SkyCatalog} from '../lib/sky/types.ts';
import type {SkyFrame} from '../lib/sky/frame-contract.ts';
const info={url:'https://upload.wikimedia.org/wikipedia/commons/a/ab/example.jpg',descriptionurl:'https://commons.wikimedia.org/wiki/File:Example.jpg',extmetadata:{Artist:{value:'NASA &amp; ESA'},LicenseShortName:{value:'Public domain'},Copyrighted:{value:'False'}}};
test('explicit Commons public-domain metadata has a source-backed rights link; unknown rights and unsafe URLs remain rejected',()=>{
 const photo=commonsImage(info);assert.equal(photo?.credit,'NASA & ESA');assert.equal(photo?.licenseUrl,info.descriptionurl+'#Licensing');
 assert.equal(commonsImage({...info,extmetadata:{...info.extmetadata,Copyrighted:{value:'True'}}}),null);
 assert.equal(commonsImage({...info,url:'http://upload.wikimedia.org/a.jpg'}),null);
 assert.equal(commonsImage({...info,mime:'image/svg+xml'}),null);
 assert.equal(commonsImage({...info,descriptionurl:'https://untrusted.test/rights'}),null);
 assert.equal(commonsImage({...info,extmetadata:{...info.extmetadata,Artist:{value:''}}}),null);
 const cc=commonsImage({...info,extmetadata:{...info.extmetadata,LicenseShortName:{value:'CC BY-SA 3.0'},LicenseUrl:{value:'http://creativecommons.org/licenses/by-sa/3.0/'},Copyrighted:{value:'True'}}});assert.equal(cc?.licenseUrl,'https://creativecommons.org/licenses/by-sa/3.0/');
 assert.equal(messierArticleTitle('M31'),'Messier 31');assert.equal(messierArticleTitle('M 42'),'Messier 42');
});
test('all curated object photographs retain complete provenance and their original content fingerprints',()=>{
 const manifest=JSON.parse(fs.readFileSync(new URL('../../../data/catalog/object-media.json',import.meta.url),'utf8'));
 assert.deepEqual(Object.keys(manifest.images).sort(),['moon','mercury','venus','mars','jupiter','saturn','uranus','neptune','hyg-32263','dso-ngc0224','dso-ngc1976'].sort());
 for(const row of Object.values(manifest.images) as any[]){const bytes=fs.readFileSync(new URL('../public'+row.url,import.meta.url));assert.equal(crypto.createHash('sha256').update(bytes).digest('hex'),row.sha256);assert.equal(bytes.length,row.bytes);assert.ok(row.credit&&row.license&&row.licenseUrl.startsWith('https://')&&row.sourceTimestamp&&row.sourceSha1);}
});
test('finder fields center the selected calculated direction, cross north without a seam and respect withheld azimuth',()=>{
 const catalog={stars:[{id:'center',magnitude:1},{id:'east',magnitude:2},{id:'west',magnitude:3}]} as SkyCatalog;
 const frame={canPublishAzimuth:true,angles:new Float64Array([0,0,1,0,359,0])} as SkyFrame;
 const field=finderField(catalog,frame,0)!;
 assert.equal(field.points[0].x,180);assert.equal(field.points[0].y,105);assert.ok(field.points.find(p=>p.id==='east')!.x>180);assert.ok(field.points.find(p=>p.id==='west')!.x<180);
 assert.equal(finderField(catalog,{...frame,canPublishAzimuth:false},0),null);assert.equal(finderField(catalog,frame,99),null);
});
test('exact object names and bilingual catalogue identifiers precede partial matches such as Marsic',()=>{
 const rows=[objectSearchEntry('marsic',['Marsic','hyg-78804']),objectSearchEntry('mars',['Mars']),objectSearchEntry('sun',['Sun','Güneş']),objectSearchEntry('m31',['M31','NGC 224','Messier 31']),objectSearchEntry('sirius',['Sirius','HIP 32349'])];
 assert.equal(findObjects(rows,'Mars')[0],'mars');assert.equal(findObjects(rows,'gunes')[0],'sun');
 for(const name of ['M 31','Messier31','NGC0224','NGC 224'])assert.equal(findObjects(rows,name)[0],'m31');
 assert.equal(findObjects(rows,'HIP32349')[0],'sirius');assert.deepEqual(findObjects(rows,' '),[]);
});
