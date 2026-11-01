import assert from 'node:assert/strict';
import test from 'node:test';
import fs from 'node:fs';
import vm from 'node:vm';
import {webcrypto,createHash} from 'node:crypto';
function harness({fail='',old=false,privateResponse=false,badOnlineMarker=false}={}){
 const resources=[{url:'/en',text:'<html>public sky</html>'},{url:'/tr',text:'<html>genel gökyüzü</html>'},{url:'/pwa/catalog.json',text:'{"public":true}'},{url:'/_next/static/worker.js',text:'/* public engine */'},{url:'/_next/static/chunks/app/%5Blang%5D/page.js',text:'/* language hydration */'},{url:'/pwa/offline-en.html',text:'Account connection needed'},{url:'/pwa/offline-tr.html',text:'Hesap bağlantısı gerekli'},{url:'/brand/wordmark.test.svg',text:'<svg>public wordmark</svg>'}];
 const row=(e:{url:string;text:string})=>({url:e.url,bytes:Buffer.byteLength(e.text),sha256:createHash('sha256').update(e.text).digest('hex')});
 const pack={version:'test-new',core:resources.map(row),optional:[row({url:'/landscapes/stara-lesna.png',text:'public image'})],coreBytes:100,optionalBytes:12};
 const stores=new Map<string,Map<string,Response>>();if(old)stores.set('yorungez-public-old',new Map([['https://sky.test/en',new Response('old public sky')]]));
 const caches={open:async(name:string)=>{if(!stores.has(name))stores.set(name,new Map());const data=stores.get(name)!;return {match:async(input:string)=>data.get(String(input))?.clone(),put:async(input:string,response:Response)=>{data.set(String(input),response.clone())}}},delete:async(name:string)=>stores.delete(name),keys:async()=>[...stores.keys()]};
 const handlers=new Map<string,(e:any)=>void>(),outbound:any[]=[],calls:any[]=[];let unreachable=false,tabCount=1,skipped=false;
 const scope={location:{origin:'https://sky.test'},navigator:{onLine:true},clients:{claim:async()=>{},matchAll:async()=>Array.from({length:tabCount},()=>({postMessage:(v:unknown)=>outbound.push(v)}))},skipWaiting:async()=>{skipped=true},addEventListener:(type:string,fn:(e:any)=>void)=>handlers.set(type,fn)};
 const fetcher=async(input:Request|string,init?:RequestInit)=>{const url=typeof input==='string'?input:input.url;calls.push({url,init});if(unreachable||url.endsWith(fail||'/never'))throw Error('network unavailable');const pathname=new URL(url).pathname;const r=resources.find(r=>r.url===pathname);return new Response(r?.text??(pathname==='/pwa-online.json'?(badOnlineMarker?'captive portal':'{"online":true}'):pathname.startsWith('/api/')?'private synthetic response':'public image'),{headers:{'Cache-Control':privateResponse?'private, no-store':'public'}})};
 const context=vm.createContext({self:scope,caches,fetch:fetcher,crypto:webcrypto,URL,Response,Headers,AbortSignal,console});
 vm.runInContext(fs.readFileSync(new URL('../lib/pwa/worker-runtime.js',import.meta.url),'utf8').replace('/*__PACK__*/',JSON.stringify(pack)),context);
 async function life(type:string){let result:Promise<unknown>|undefined;handlers.get(type)!({waitUntil:(p:Promise<unknown>)=>result=p});return result}
 async function request(path:string,method='GET',headers:Record<string,string>={},mode='cors'){let result:Promise<Response>|undefined;handlers.get('fetch')!({request:{url:'https://sky.test'+path,method,headers:new Headers(headers),mode},respondWith:(p:Promise<Response>)=>result=p});return result!}
 async function message(type:string){let result:Promise<unknown>|undefined;handlers.get('message')!({data:{type},source:{url:'https://sky.test/en',postMessage:(v:unknown)=>outbound.push(v)},waitUntil:(p:Promise<unknown>)=>result=p});await result}
 return {stores,calls,outbound,life,request,message,offline:()=>unreachable=true,online:()=>unreachable=false,tabs:(n:number)=>tabCount=n,skipped:()=>skipped};
}
test('the installed public shell, worker and catalogue reopen when the server is unreachable',async()=>{
 const h=harness();await h.life('install');h.offline();
 assert.match(await (await h.request('/en','GET',{},'navigate')).text(),/public sky/);
 assert.match(await (await h.request('/pwa/catalog.json')).text(),/public/);
 assert.match(await (await h.request('/_next/static/worker.js')).text(),/engine/);
 assert.match(await (await h.request('/_next/static/chunks/app/%5Blang%5D/page.js')).text(),/hydration/);
 assert.match(await (await h.request('/brand/wordmark.test.svg')).text(),/public wordmark/);
 assert.equal(h.calls.length,8); // reopen used the verified pack, not failed network requests
});
test('private APIs, POSTs, sensitive queries and RSC requests never enter the public cache',async()=>{
 const h=harness();await h.life('install');
 for(const [path,method,headers] of [['/api/account/me','GET',{}],['/api/notebook','GET',{}],['/api/location/time-zone','POST',{}],['/en?latitude=41','GET',{}],['/en','GET',{RSC:'1'}]] as const)await h.request(path,method,headers);
 const keys=[...h.stores.values()].flatMap(v=>[...v.keys()]);assert.equal(keys.length,9);assert.ok(keys.every(k=>!k.includes('/api/')&&!k.includes('?')));
 h.offline();assert.equal((await h.request('/api/notebook')).status,503);
 assert.match(await (await h.request('/en/account/confirm-email','GET',{},'navigate')).text(),/Account connection needed/);
});
test('a failed or private-response update leaves the previously working public pack intact',async()=>{
 for(const options of [{fail:'/pwa/catalog.json',old:true},{privateResponse:true,old:true}]){const h=harness(options);await assert.rejects(()=>h.life('install'));assert.ok(h.stores.has('yorungez-public-old'));assert.ok(!h.stores.has('yorungez-public-test-new'))}
});
test('an update waits for other tabs and an explicit action before replacing their shell',async()=>{
 const h=harness();await h.life('install');h.tabs(2);await h.message('ACTIVATE_UPDATE');assert.equal(h.skipped(),false);assert.equal(h.outbound.at(-1).type,'UPDATE_BLOCKED');
 h.tabs(1);await h.message('ACTIVATE_UPDATE');assert.equal(h.skipped(),true);
});


test('activating an older installed worker never deletes a newer waiting public pack',async()=>{
 const h=harness({old:true});await h.life('install');
 h.stores.set('yorungez-public-future',new Map([['https://sky.test/en',new Response('future public sky')]]));
 await h.life('activate');assert.ok(!h.stores.has('yorungez-public-old'));assert.ok(h.stores.has('yorungez-public-future'));
 await h.message('CLEAN_OLD_PACKS');assert.ok(h.stores.has('yorungez-public-future'));
});


test('public connection checks recover from server outage without caching their probe or personal data',async()=>{
 const h=harness();await h.life('install');h.offline();await h.message('CHECK_NETWORK');
 assert.equal(h.outbound.at(-1).unavailable,true);
 h.online();await Promise.all([h.message('CHECK_NETWORK'),h.message('CHECK_NETWORK'),h.message('CHECK_NETWORK')]);
 assert.equal(h.outbound.at(-1).unavailable,false);
 const probes=h.calls.filter(c=>c.url.endsWith('/pwa-online.json'));assert.equal(probes.length,2);
 assert.ok(probes.every(p=>p.init.credentials==='omit'&&p.init.cache==='no-store'));
 assert.ok([...h.stores.values()].every(v=>![...v.keys()].some(k=>k.includes('pwa-online'))));
 const captive=harness({badOnlineMarker:true});await captive.life('install');await captive.message('CHECK_NETWORK');
 assert.equal(captive.outbound.at(-1).unavailable,true); // HTTP 200 is not sufficient evidence of this app being online.
});
