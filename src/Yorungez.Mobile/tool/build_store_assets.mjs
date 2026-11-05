// Native SVG layout export: original brand + genuine app PNGs + decorative AI backdrop.
// App screenshots are never sent through a generative edit or painted over.
import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {createRequire} from 'node:module';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../../..');
const require=createRequire(path.join(root,'src/Yorungez.Web/package.json'));
const sharp=require('sharp');
const output=path.join(root,'data/store/google-play/en-US');
await fs.mkdir(path.join(output,'screenshots'),{recursive:true});
const escape=value=>value.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;');
const embed=async file=>'data:image/'+(file.endsWith('.svg')?'svg+xml':'png')+';base64,'+(await fs.readFile(file)).toString('base64');
const mark=await embed(path.join(root,'data/branding/exports/mark-on-dark.svg'));
const manifest={locale:'en-US',app:'Yorungez',art:'Built-in image_gen, decorative only',capture:'Android API 34 isolated emulator; actual Flutter widgets/native solver; public Istanbul example',files:{}};
const sha=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
async function save(file,bytes){await fs.writeFile(path.join(output,file),bytes);const m=await sharp(bytes).metadata();manifest.files[file]={width:m.width,height:m.height,channels:m.channels,bytes:bytes.length,sha256:sha(bytes)};}
const slides=[
 ['01-jupiter','Explore your sky',['Your sky.','A closer look.'],['Planets, stars and the directions','that connect you to them.']],
 ['02-moon','Our nearest neighbour',['Meet the Moon.'],['Explore its phase and position','for your chosen place and time.']],
 ['03-orion','Constellations, revealed',['See the stories','in the stars.'],['Reveal constellation lines','and illustrated figures.']],
 ['04-andromeda','Let curiosity guide you',['Go beyond','the familiar.'],['Discover Andromeda and the','objects that make you curious.']],
 ['05-tonight','A plan for the night',['Make tonight','an adventure.'],['Find observing windows.','Choose a time and a target.']],
 ['06-calendar','Celestial moments',['A sky worth','making time for.'],['Sourced events. Local time.','Email reminders for your plans.']],
 ['07-catalogue','Explore at your own pace',['Curiosity,','without a signal.'],['Search the bundled sky catalogue','and discover something new.']],
 ['08-account','Your personal observatory',['Keep your','discoveries.'],['Notes and favourites.','One account across your devices.']],
];
for(const [index,[id,eyebrow,headline,body]] of slides.entries()){
 const rawFile=path.join(output,'raw',id+'.png'),rawBytes=await fs.readFile(rawFile),rawMeta=await sharp(rawBytes).metadata();
 if(rawMeta.width!==1080||rawMeta.height!==2268)throw new Error('Unexpected actual capture dimensions for '+id);
 const screen=await embed(rawFile),art=await embed(path.join(output,'art',id+'.png'));
 const screenWidth=700,screenHeight=screenWidth*rawMeta.height/rawMeta.width;
 const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="1920" viewBox="0 0 1080 1920">
 <defs><clipPath id="screen"><rect x="190" y="430" width="${screenWidth}" height="${screenHeight}" rx="34"/></clipPath><filter id="shadow" x="-40%" y="-20%" width="180%" height="150%"><feDropShadow dx="0" dy="18" stdDeviation="24" flood-color="#000" flood-opacity=".65"/></filter></defs>
 <image href="${art}" width="1080" height="1920" preserveAspectRatio="xMidYMid slice"/>
 <rect width="1080" height="430" fill="#17191C" opacity=".28"/>
 <image href="${mark}" x="80" y="62" width="58" height="52"/>
 <text x="156" y="101" fill="#F7F1E6" font-family="Arial,sans-serif" font-size="34" font-weight="700">Yorungez</text>
 <text x="996" y="98" text-anchor="end" fill="#C9B6A6" font-family="Arial,sans-serif" font-size="20" letter-spacing="3">${String(index+1).padStart(2,'0')} / 08</text>
 <text x="84" y="158" fill="#C9B6A6" font-family="Arial,sans-serif" font-size="23" letter-spacing="1.3">${escape(eyebrow)}</text>
 <text fill="#F7F1E6" font-family="Arial,sans-serif" font-size="76" font-weight="700" letter-spacing="-2">${headline.map((line,n)=>`<tspan x="80" y="${245+n*79}">${escape(line)}</tspan>`).join('')}</text>
 <text fill="#C9B6A6" font-family="Arial,sans-serif" font-size="28">${body.map((line,n)=>`<tspan x="84" y="${headline.length===1?319+n*40:373+n*36}">${escape(line)}</tspan>`).join('')}</text>
 <rect x="182" y="422" width="716" height="${screenHeight+16}" rx="42" fill="#3C3F43" stroke="#9EA1A6" stroke-opacity=".45" stroke-width="2" filter="url(#shadow)"/>
 <image href="${screen}" x="190" y="430" width="${screenWidth}" height="${screenHeight}" clip-path="url(#screen)"/>
 </svg>`;
 await save('screenshots/'+id+'.png',await sharp(Buffer.from(svg)).removeAlpha().png().toBuffer());
 manifest.files['screenshots/'+id+'.png'].captureSha256=sha(rawBytes);
}
const featureArt=await embed(path.join(output,'art/feature-art.png'));
const feature=`<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="500"><image href="${featureArt}" width="1024" height="500" preserveAspectRatio="xMidYMid slice"/>
 <image href="${mark}" x="56" y="48" width="80" height="72"/>
 <text x="158" y="103" fill="#F7F1E6" font-family="Arial,sans-serif" font-size="46" font-weight="700">Yorungez</text>
 <text x="58" y="225" fill="#F7F1E6" font-family="Arial,sans-serif" font-size="55" font-weight="700" letter-spacing="-1.6">A little curiosity.</text>
 <text x="58" y="293" fill="#F7F1E6" font-family="Arial,sans-serif" font-size="55" font-weight="700" letter-spacing="-1.6">An entire universe.</text>
 <rect x="60" y="330" width="82" height="4" fill="#8B2333"/>
 <text x="58" y="381" fill="#C9B6A6" font-family="Arial,sans-serif" font-size="24">Explore the sky. Understand what you see.</text>
 <text x="60" y="451" fill="#9EA1A6" font-family="Arial,sans-serif" font-size="18" letter-spacing="1">yorungez.com</text></svg>`;
await save('feature-graphic.png',await sharp(Buffer.from(feature)).removeAlpha().png().toBuffer());
await save('icon-512.png',await fs.readFile(path.join(root,'data/branding/mobile/google-play-icon-512.png')));
// A review sheet is not a Play upload asset; it keeps all eight native layouts visible.
const previews=[];
for(const [n,[id]] of slides.entries())previews.push({input:await sharp(path.join(output,'screenshots',id+'.png')).resize(440,782).toBuffer(),left:24+(n%4)*476,top:110+Math.floor(n/4)*818});
const title=Buffer.from('<svg width="1928" height="96"><text x="24" y="62" fill="#F7F1E6" font-family="Arial,sans-serif" font-weight="700" font-size="36">Yorungez · Google Play showcase · English</text></svg>');
await save('overview.jpg',await sharp({create:{width:1928,height:1760,channels:3,background:'#17191C'}}).composite([{input:title,left:0,top:0},...previews]).jpeg({quality:90}).toBuffer());
await fs.writeFile(path.join(output,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
console.log('Exported 8 portrait 1080×1920 PNGs, 1024×500 feature graphic, 512 icon and review sheet.');
