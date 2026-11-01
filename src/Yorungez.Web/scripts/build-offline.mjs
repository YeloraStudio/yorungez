import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
const web=process.cwd(),dist=path.join(web,process.env.YORUNGEZ_BUILD_DIR==='.next-preview'?'.next-preview':'.next');
const digest=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
async function walk(dir){const rows=[];for(const e of await fs.readdir(dir,{withFileTypes:true})){const file=path.join(dir,e.name);if(e.isDirectory())rows.push(...await walk(file));else rows.push(file)}return rows}
async function entry(url,file){const bytes=await fs.readFile(file);return {url,bytes:bytes.length,sha256:digest(bytes)}}
const core=[];
for(const lang of ['en','tr'])core.push(await entry('/'+lang,path.join(dist,'server/app',lang+'.html')));
for(const file of await walk(path.join(dist,'static')))if(/\.(js|css|woff2)$/.test(file))core.push(await entry('/_next/static/'+path.relative(path.join(dist,'static'),file).replaceAll('\\','/').split('/').map(encodeURIComponent).join('/'),file));
for(const name of ['catalog.json','calendar.json','icon-192.png','icon-512.png','offline-en.html','offline-tr.html'])core.push(await entry('/pwa/'+name,path.join(web,'public/pwa',name)));
core.push(await entry('/favicon.svg',path.join(web,'public/favicon.svg')));
const urls=new Set(core.map(e=>e.url));
for(const lang of ['en','tr']){
 const html=await fs.readFile(path.join(dist,'server/app',lang+'.html'),'utf8');
 for(const m of html.matchAll(/(?:src|href)="(\/_next\/static\/[^"?]+)"/g))if(!urls.has(m[1]))throw new Error('Missing encoded shell dependency: '+m[1]);
}
const optional=[];
for(const folder of ['landscapes','sky-art','objects'])for(const file of await walk(path.join(web,'public',folder)))if(/\.(png|webp|jpg)$/.test(file))optional.push(await entry('/'+path.relative(path.join(web,'public'),file).replaceAll('\\','/'),file));
const runtime=await fs.readFile(path.join(web,'lib/pwa/worker-runtime.js'),'utf8');
const version=digest(JSON.stringify(core)+JSON.stringify(optional)+runtime).slice(0,20);
const pack={version,core,optional,coreBytes:core.reduce((a,e)=>a+e.bytes,0),optionalBytes:optional.reduce((a,e)=>a+e.bytes,0)};
await fs.mkdir(path.join(dist,'yorungez-pwa'),{recursive:true});
await fs.writeFile(path.join(dist,'yorungez-pwa/pack.json'),JSON.stringify(pack));
await fs.writeFile(path.join(dist,'yorungez-pwa/worker.js'),runtime.replace('/*__PACK__*/',JSON.stringify(pack)));
console.log(`Public offline pack ${version}: ${core.length} core files (${(pack.coreBytes/1048576).toFixed(1)} MiB), ${optional.length} optional images (${(pack.optionalBytes/1048576).toFixed(1)} MiB).`);
