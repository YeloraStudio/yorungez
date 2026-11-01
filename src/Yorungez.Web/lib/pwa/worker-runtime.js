/* General public data only. Never persist requests, credentials or account responses. */
const PACK=/*__PACK__*/;
const PREFIX='yorungez-public-',NAME=PREFIX+PACK.version,CORE=new Map(PACK.core.map(e=>[e.url,e])),OPTIONAL=new Map(PACK.optional.map(e=>[e.url,e]));
let networkUnavailable=false,optionalJob=null,networkJob=null;
const canonical=url=>new URL(url,self.location.origin).href;
function publicEntry(request){const url=new URL(request.url);if(request.method!=='GET'||url.origin!==self.location.origin||url.search||request.headers.has('Range')||request.headers.has('RSC'))return null;return CORE.get(url.pathname)||OPTIONAL.get(url.pathname)||null}
async function broadcast(data){for(const c of await self.clients.matchAll({type:'window'}))c.postMessage(data)}
async function networkState(failed){if(networkUnavailable!==failed){networkUnavailable=failed;await broadcast({type:'NETWORK_STATE',unavailable:failed})}}
async function verifiedFetch(entry){
 const response=await fetch(canonical(entry.url),{credentials:'omit',cache:'reload',redirect:'error',signal:AbortSignal.timeout(20000)});
 if(!response.ok||response.type==='opaque'||/private|no-store/i.test(response.headers.get('Cache-Control')||''))throw Error('public-pack-response');
 const bytes=await response.clone().arrayBuffer(),hash=Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',bytes)),b=>b.toString(16).padStart(2,'0')).join('');
 if(hash!==entry.sha256)throw Error('public-pack-integrity');return response;
}
async function fill(entries){const cache=await caches.open(NAME);for(let i=0;i<entries.length;i+=4)await Promise.all(entries.slice(i,i+4).map(async entry=>{if(!await cache.match(canonical(entry.url)))await cache.put(canonical(entry.url),await verifiedFetch(entry))}))}
self.addEventListener('install',event=>{event.waitUntil((async()=>{try{const previous=(await caches.keys()).filter(k=>k.startsWith(PREFIX)&&k!==NAME);await fill(PACK.core);const cache=await caches.open(NAME);await cache.put(canonical('/pwa/internal-predecessors.json'),Response.json(previous))}catch(e){await caches.delete(NAME);throw e}})())});
self.addEventListener('activate',event=>{event.waitUntil((async()=>{
 // Updates are only forced with one open client and an explicit save/reload action.
 await self.clients.claim();await broadcast({type:'PACK_ACTIVE',version:PACK.version});
 const cache=await caches.open(NAME),metadata=await cache.match(canonical('/pwa/internal-predecessors.json'));
 const predecessors=metadata?await metadata.json():[];
 // Installation records only preceding versions. A future waiting pack is never in this list.
 for(const name of predecessors)if(typeof name==='string'&&name.startsWith(PREFIX)&&name!==NAME)await caches.delete(name);
})())});
async function status(){const cache=await caches.open(NAME);const present=await Promise.all(PACK.optional.map(e=>cache.match(canonical(e.url))));return {type:'PACK_STATUS',version:PACK.version,coreReady:(await Promise.all(PACK.core.map(e=>cache.match(canonical(e.url))))).every(Boolean),optionalReady:present.every(Boolean),optionalCount:present.filter(Boolean).length,optionalTotal:PACK.optional.length,coreBytes:PACK.coreBytes,optionalBytes:PACK.optionalBytes,unavailable:networkUnavailable}}
self.addEventListener('message',event=>{
 // Accept only our own same-origin window clients, not arbitrary postMessage payloads.
 if(!event.source?.url||new URL(event.source.url).origin!==self.location.origin)return;
 const reply=data=>event.source.postMessage(data);
 if(event.data?.type==='STATUS')event.waitUntil(status().then(reply));
 if(event.data?.type==='REPAIR_CORE')event.waitUntil(fill(PACK.core).catch(()=>reply({type:'PACK_ERROR'})).then(()=>status()).then(reply));
 if(event.data?.type==='CACHE_IMAGES'){if(!optionalJob)optionalJob=fill(PACK.optional).then(()=>networkState(false)).catch(()=>reply({type:'PACK_ERROR'})).finally(()=>{optionalJob=null});event.waitUntil(optionalJob.then(()=>status()).then(reply))}
 if(event.data?.type==='ACTIVATE_UPDATE')event.waitUntil(self.clients.matchAll({type:'window',includeUncontrolled:true}).then(tabs=>tabs.length>1?reply({type:'UPDATE_BLOCKED'}):self.skipWaiting()));
 if(event.data?.type==='CHECK_NETWORK'){
  if(!networkJob)networkJob=fetch(canonical('/pwa-online.json'),{cache:'no-store',credentials:'omit',signal:AbortSignal.timeout(4000)}).then(async r=>{if(!r.ok||(await r.json()).online!==true)throw Error('not-online-marker');return networkState(false)}).catch(()=>networkState(true)).finally(()=>{networkJob=null});
  event.waitUntil(networkJob.then(()=>status()).then(reply));
 }

});
async function publicResponse(request,entry){const cache=await caches.open(NAME),hit=await cache.match(canonical(entry.url));if(hit)return hit;
 try{const response=await verifiedFetch(entry);await cache.put(canonical(entry.url),response.clone());await networkState(false);return response}catch{await networkState(true);return new Response('',{status:503})}}
self.addEventListener('fetch',event=>{
 const request=event.request,url=new URL(request.url);if(url.origin!==self.location.origin)return;
 const entry=publicEntry(request);
 if(entry){event.respondWith(publicResponse(request,entry));return}
 if(request.mode==='navigate'&&!url.search&&['/','/en','/tr'].includes(url.pathname)){
  event.respondWith(publicResponse(request,CORE.get(url.pathname==='/'?'/en':url.pathname)));return;
 }
 // No cached fallback for personal/API operations. A failed navigation gets a neutral public page.
 event.respondWith(fetch(request,{cache:'no-store'}).catch(async()=>{
  await networkState(true);
  if(request.mode==='navigate'){const cache=await caches.open(NAME);return await cache.match(canonical(url.pathname.startsWith('/tr')?'/pwa/offline-tr.html':'/pwa/offline-en.html'))||new Response('Connection needed',{status:503})}
  return Response.json({code:self.navigator?.onLine===false?'Account.Offline':'Common.Unavailable'},{status:503,headers:{'Cache-Control':'no-store, private'}});
 }));
});
