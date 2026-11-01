import fs from 'node:fs/promises';
import path from 'node:path';
import sharp from 'sharp';
export async function stageOffline(web){
 const read=async name=>JSON.parse(await fs.readFile(path.join(web,'generated',name),'utf8'));
 const [catalog,manifest,glossary,overlays,overlayManifest]=await Promise.all(['catalog.json','manifest.json','glossary.json','overlays.json','overlays-manifest.json'].map(read));
 const provenance=Object.fromEntries(['version','derivedSha256','starCount','brightCount','constellationCount','sources','attribution','limitations'].map(k=>[k,manifest[k]]));
 const dir=path.join(web,'public/pwa');await fs.mkdir(dir,{recursive:true});
 await fs.writeFile(path.join(dir,'catalog.json'),JSON.stringify({catalog:{...catalog,deepSky:overlays.deepSky,art:overlays.art},provenance,overlayProvenance:{sha256:overlayManifest.sha256,attribution:overlayManifest.attribution},glossary}));
 await fs.copyFile(path.join(web,'generated/calendar.json'),path.join(dir,'calendar.json'));
 const icon=await fs.readFile(path.join(web,'public/favicon.svg'));
 for(const size of [192,512])await sharp(icon).resize(size,size).png().toFile(path.join(dir,`icon-${size}.png`));
 for(const lang of ['en','tr']){
  const tr=lang==='tr';
  await fs.writeFile(path.join(dir,`offline-${lang}.html`),`<!doctype html><html lang="${lang}"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>yorungez · ${tr?'Bağlantı gerekli':'Connection needed'}</title><style>body{margin:0;background:#3C3F43;color:#F7F1E6;font:16px/1.6 system-ui;display:grid;min-height:100vh;place-items:center}main{max-width:36rem;padding:2rem}a{color:#C9B6A6}h1{color:#F7F1E6}strong{color:#C9B6A6}</style><main><strong>yorungez.</strong><h1>${tr?'Bu sayfa için bağlantı gerekli':'This page needs a connection'}</h1><p>${tr?'Hesap işlemleri ve kişisel kayıtlar sunucuda tutulur. Bağlantı kurduğunda bu sayfayı yeniden aç. E-posta bağlantısını kullanıyorsan aynı bağlantıyı gelen kutundan tekrar açabilirsin.':'Account actions and personal records are stored on the server. Reopen this page when connected. For an email action, reopen the same link from your inbox.'}</p><p><a href="/${lang}">${tr?'Önbellekteki gökyüzüne dön':'Return to the cached sky'}</a></p></main></html>`);
 }
}
