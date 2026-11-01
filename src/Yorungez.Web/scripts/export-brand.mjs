// Explicit, deterministic format exports. Normal builds only verify these checked-in files.
import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import sharp from 'sharp';
const web=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..'),root=path.resolve(web,'../..');
const brand=path.join(root,'data/branding'),output=path.join(web,'public/brand');
await fs.mkdir(output,{recursive:true});
const sha=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
const manifest={version:1,assets:{}};
async function publish(role,name,bytes,dimensions){
 const ext=path.extname(name),stem=path.basename(name,ext),hash=sha(bytes),file=`${stem}.${hash.slice(0,12)}${ext}`;
 await fs.writeFile(path.join(output,file),bytes);
 manifest.assets[role]={src:'/brand/'+file,...dimensions,bytes:bytes.length,sha256:hash};
}
for(const [role,file] of Object.entries({wordmarkDark:'wordmark-on-dark.svg',wordmarkLight:'wordmark-on-light.svg',markDark:'mark-on-dark.svg',markLight:'mark-on-light.svg'})){
 const bytes=await fs.readFile(path.join(brand,'exports',file)),m=await sharp(bytes).metadata();
 await publish(role,file,bytes,{width:m.width,height:m.height});
}
const artwork=await fs.readFile(path.join(brand,'source/app-icon-fullbleed.png'));
for(const size of [192,512])await publish('app'+size,`app-${size}.png`,await sharp(artwork).resize(size,size).removeAlpha().png().toBuffer(),{width:size,height:size});
await publish('apple180','apple-touch-180.png',await sharp(artwork).resize(180,180).removeAlpha().png().toBuffer(),{width:180,height:180});
// The emblem fits inside the standard central safe circle, even under a circular launcher mask.
const emblem=await sharp(path.join(brand,'exports/mark-on-dark.svg')).resize(280,250,{fit:'inside'}).png().toBuffer();
await publish('maskable512','maskable-512.png',await sharp({create:{width:512,height:512,channels:3,background:'#3C3F43'}}).composite([{input:emblem,gravity:'centre'}]).removeAlpha().png().toBuffer(),{width:512,height:512});
const mark=await fs.readFile(path.join(brand,'exports/mark-on-light.svg'),'utf8');
const favicon=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64"><rect width="64" height="64" rx="12" fill="#F7F1E6"/>${mark.replace('<svg ','<svg x="6" y="8" width="52" height="48" ').replace(/ width="1010" height="905"/,'')}</svg>`);
await publish('faviconSvg','favicon.svg',favicon,{width:64,height:64});
const icoImages=[];
for(const size of [16,32,48]){
 const bytes=await sharp(favicon).resize(size,size).png().toBuffer();icoImages.push({size,bytes});
 if(size!==48)await publish('favicon'+size,`favicon-${size}.png`,bytes,{width:size,height:size});
}
const header=Buffer.alloc(6+16*icoImages.length);header.writeUInt16LE(1,2);header.writeUInt16LE(icoImages.length,4);
let offset=header.length;
icoImages.forEach(({size,bytes},i)=>{const pos=6+16*i;header[pos]=size;header[pos+1]=size;header.writeUInt16LE(1,pos+4);header.writeUInt16LE(32,pos+6);header.writeUInt32LE(bytes.length,pos+8);header.writeUInt32LE(offset,pos+12);offset+=bytes.length});
const ico=Buffer.concat([header,...icoImages.map(i=>i.bytes)]);
await publish('faviconIco','favicon.ico',ico,{width:48,height:48});
await fs.writeFile(path.join(web,'public/favicon.svg'),favicon);
await fs.writeFile(path.join(web,'public/favicon.ico'),ico);
const email=await sharp(path.join(brand,'exports/wordmark-on-light.svg')).resize(720).flatten({background:'#F7F1E6'}).png().toBuffer();
await fs.writeFile(path.join(brand,'exports/email-wordmark.png'),email);
const emailMeta=await sharp(email).metadata();
manifest.email={file:'data/branding/exports/email-wordmark.png',width:emailMeta.width,height:emailMeta.height,bytes:email.length,sha256:sha(email)};
await fs.writeFile(path.join(brand,'assets.json'),JSON.stringify(manifest,null,2)+'\n');
console.log(`Exported ${Object.keys(manifest.assets).length} web brand assets and one embedded email wordmark.`);
