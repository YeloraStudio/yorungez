import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import {publicMeasurementPage,readAnalyticsChoice} from '../lib/measurement.ts';
import {webBuildId} from '../scripts/web-build-id.mjs';
test('measurement excludes private, query and fragment contexts instead of leaking their contents',()=>{
 for(const path of ['/en/account/reset-password','/tr/account/confirm-email','/api/account','/en/lab/renderers','/en?lat=40','/en#token=private','/tr/library/moon-phases?query=secret','/en/notebook','/en/library/../account'])assert.equal(publicMeasurementPage(path),null);
 const page=publicMeasurementPage('/tr/library/moon-phases');assert.equal(page?.page_location,'https://yorungez.com/tr/library/moon-phases');assert.equal(page?.page_referrer,'');
 assert.equal(readAnalyticsChoice('x=1; yorungez-analytics=accepted; z=2'),'accepted');assert.equal(readAnalyticsChoice('yorungez-analytics=declined'),'declined');assert.equal(readAnalyticsChoice('yorungez-analytics=true'),null);assert.equal(readAnalyticsChoice(''),null);
});
test('Web build identity changes for public Web inputs and ignores unrelated backend/native/private changes',async()=>{
 const root=await fs.mkdtemp(path.join(os.tmpdir(),'yorungez-web-id-'));const web=path.join(root,'src/Web');
 try{await fs.mkdir(path.join(web,'app'),{recursive:true});await fs.writeFile(path.join(web,'app/page.tsx'),'sky A');const a=await webBuildId(web);assert.equal(await webBuildId(web),a);
  await fs.mkdir(path.join(root,'native'),{recursive:true});await fs.writeFile(path.join(root,'native/main.dart'),'changed');await fs.writeFile(path.join(web,'.env'),'PRIVATE=not-part-of-build-id');assert.equal(await webBuildId(web),a);
  await fs.writeFile(path.join(web,'app/page.tsx'),'sky B');assert.notEqual(await webBuildId(web),a);
 }finally{await fs.rm(root,{recursive:true,force:true});}
});
