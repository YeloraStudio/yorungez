// Deterministic native/store size exports of the existing owner brand; no new logo.
import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {createRequire} from 'node:module';
const app=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..'),root=path.resolve(app,'../..');
const require=createRequire(path.join(root,'src/Yorungez.Web/package.json'));
const sharp=require('sharp');
const output=path.join(root,'data/branding/mobile');
await fs.mkdir(output,{recursive:true});
const artwork=await fs.readFile(path.join(root,'data/branding/source/app-icon-fullbleed.png'));
const mark=await fs.readFile(path.join(root,'data/branding/exports/mark-on-dark.svg'),'utf8');
const sha=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
const manifest={source:'data/branding/source/app-icon-fullbleed.png',sourceSha256:sha(artwork),emblem:'data/branding/exports/mark-on-dark.svg',emblemSha256:sha(Buffer.from(mark)),files:{}};
async function save(name,bytes){await fs.writeFile(path.join(output,name),bytes);const m=await sharp(bytes).metadata();manifest.files[name]={width:m.width,height:m.height,channels:m.channels,bytes:bytes.length,sha256:sha(bytes)};}
await save('app-icon-1024.png',await sharp(artwork).resize(1024,1024).removeAlpha().png().toBuffer());
await save('google-play-icon-512.png',await sharp(artwork).resize(512,512).ensureAlpha().png().toBuffer());
for(const [name,source] of [['adaptive-foreground.png',mark],['adaptive-monochrome.png',mark.replace(/fill="#[0-9A-Fa-f]{6}"/g,'fill="#FFFFFF"')]]){
 const emblem=await sharp(Buffer.from(source)).resize({width:450,height:403,fit:'inside'}).png().toBuffer();
 const bytes=await sharp({create:{width:1024,height:1024,channels:4,background:'#00000000'}}).composite([{input:emblem,gravity:'centre'}]).png().toBuffer();
 const {data,info}=await sharp(bytes).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 const radius=1024*33/108;
 for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++)if(data[(y*info.width+x)*4+3]>0&&Math.hypot(x-511.5,y-511.5)>radius)throw new Error('Adaptive emblem leaves safe circle');
 await save(name,bytes);
}
await fs.writeFile(path.join(output,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
console.log('Exported four existing-brand masters; adaptive/monochrome safe circles verified.');
