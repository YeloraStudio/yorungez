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
// Native launch artwork uses the same original cosmic image as the legacy
// launcher, never the flat emblem. The circle is an OS launch-screen mask only.
const circle=Buffer.from('<svg width="512" height="512"><circle cx="256" cy="256" r="256" fill="white"/></svg>');
const launch=await sharp(artwork).resize(512,512).ensureAlpha().composite([{input:circle,blend:'dest-in'}]).png().toBuffer();
await save('launch-icon-512.png',launch);
// Android 12+: content fits the 192/288 central circle. Keep padding transparent
// so Android does not crop the actual logo or show a separate grey icon tile.
const splash=await sharp({create:{width:768,height:768,channels:4,background:'#00000000'}}).composite([{input:launch,left:128,top:128}]).png().toBuffer();
await save('android-splash-768.png',splash);
const android=path.join(app,'android/app/src/main/res/drawable-nodpi');
await fs.mkdir(android,{recursive:true});
// AdaptiveIconDrawable expands layers by 25% on every side. Mirror only the
// off-mask overscan: its central 512px viewport is the unchanged cosmic image.
// This prevents the OS from adding a white legacy-icon frame or zooming in.
const adaptive=await sharp(artwork).resize(512,512).extend({top:128,bottom:128,left:128,right:128,extendWith:'mirror'}).png().toBuffer();
await save('android-launcher-768.png',adaptive);
await fs.writeFile(path.join(android,'yorungez_launcher.png'),adaptive);
await fs.writeFile(path.join(android,'yorungez_launch_icon.png'),launch);
await fs.writeFile(path.join(android,'yorungez_splash.png'),splash);
const ios=path.join(app,'ios/Runner/Assets.xcassets/LaunchImage.imageset');
for(const [scale,name] of [[1,'LaunchImage.png'],[2,'LaunchImage@2x.png'],[3,'LaunchImage@3x.png']])await fs.writeFile(path.join(ios,name),await sharp(launch).resize(168*scale,168*scale).png().toBuffer());
await fs.writeFile(path.join(output,'manifest.json'),JSON.stringify({...manifest,nativeLauncher:'Original cosmic artwork in the central viewport; mirrored adaptive overscan; no flat emblem',nativeLaunch:'Source artwork with circle mask; Android 12 central 192/288 safe area'},null,2)+'\n');
console.log('Exported existing-brand masters and Android/iOS cosmic launch assets.');
