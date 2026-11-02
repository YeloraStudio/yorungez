import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
const web = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const root = path.resolve(web, '../..');
const source = fs.readFileSync(path.join(root, 'data/catalog/bright-sky.json'));
const manifest = JSON.parse(fs.readFileSync(path.join(root, 'data/catalog/manifest.json')));
if (crypto.createHash('sha256').update(source).digest('hex') !== manifest.derivedSha256)
  throw new Error('Catalogue content does not match its source manifest');
const catalog = JSON.parse(source);
const ids = new Set(catalog.stars.map(s => s.id));
if (ids.size !== catalog.stars.length || catalog.constellations.length !== 88)
  throw new Error('Invalid catalogue identities');
for (const c of catalog.constellations) {
  if (!c.names.tr || !c.names.en) throw new Error('Missing constellation translation');
  for (const line of c.lines) for (const id of line) if (!ids.has(id)) throw new Error('Unresolved line node');
}
const generated = path.join(web, 'generated');
fs.mkdirSync(generated, { recursive: true });
fs.copyFileSync(path.join(root, 'data/catalog/bright-sky.json'), path.join(generated, 'catalog.json'));
fs.copyFileSync(path.join(root, 'data/catalog/manifest.json'), path.join(generated, 'manifest.json'));
fs.copyFileSync(path.join(root, 'src/Modules/Catalog/Yorungez.Catalog.Infrastructure/Data/glossary.json'), path.join(generated, 'glossary.json'));
const overlayBytes=fs.readFileSync(path.join(root,'data/catalog/overlays.json'));
const overlayManifest=JSON.parse(fs.readFileSync(path.join(root,'data/catalog/overlays-manifest.json')));
if(crypto.createHash('sha256').update(overlayBytes).digest('hex')!==overlayManifest.sha256)throw new Error('Overlay fingerprint mismatch');
for(const asset of overlayManifest.artFiles){if(crypto.createHash('sha256').update(fs.readFileSync(path.join(root,asset.file))).digest('hex')!==asset.sha256)throw new Error('Artwork fingerprint mismatch');}
for(const file of ['overlays.json','overlays-manifest.json','sun-content.json'])fs.copyFileSync(path.join(root,'data/catalog',file),path.join(generated,file));
const sun=JSON.parse(fs.readFileSync(path.join(generated,'sun-content.json')));
for(const row of Object.values(sun))if(row.image?.sha256&&crypto.createHash('sha256').update(fs.readFileSync(path.join(web,'public',row.image.url))).digest('hex')!==row.image.sha256)throw new Error('Object photograph fingerprint mismatch');
const media=JSON.parse(fs.readFileSync(path.join(root,'data/catalog/object-media.json'),'utf8'));
for(const row of Object.values(media.images))if(crypto.createHash('sha256').update(fs.readFileSync(path.join(web,'public',row.url))).digest('hex')!==row.sha256)throw new Error('Object photograph fingerprint mismatch');
const photos={sun:sun.en.image,...media.images};
const features=JSON.parse(fs.readFileSync(path.join(root,'data/catalog/sky-features.json'),'utf8'));
for(const row of Object.values(features).filter(value=>typeof value==='object'))if(crypto.createHash('sha256').update(fs.readFileSync(path.join(web,'public',row.image.url))).digest('hex')!==row.image.sha256)throw new Error('Sky feature photograph fingerprint mismatch');
fs.copyFileSync(path.join(root,'data/catalog/sky-features.json'),path.join(generated,'sky-features.json'));
fs.writeFileSync(path.join(generated,'object-photos.json'),JSON.stringify(Object.fromEntries(Object.entries(photos).map(([id,row])=>[id,Object.fromEntries(['url','sourceUrl','credit','license','licenseUrl'].map(key=>[key,row[key]]))]))));
console.log(`Staged verified catalogue: ${catalog.stars.length} stars, 88 constellation identities.`);

const landscape=JSON.parse(fs.readFileSync(path.join(root,'data/catalog/landscape-manifest.json')));
if(crypto.createHash('sha256').update(fs.readFileSync(path.join(root,landscape.file))).digest('hex')!==landscape.sha256)throw new Error('Landscape photograph fingerprint mismatch');

for(const [folder,dataFile,manifestFile] of [['events','calendar.json','calendar-manifest.json'],['places','cities.json.gz','places-manifest.json']]){
 const data=fs.readFileSync(path.join(root,'data',folder,dataFile)),m=fs.readFileSync(path.join(root,'data',folder,'manifest.json'));
 if(crypto.createHash('sha256').update(data).digest('hex')!==JSON.parse(m).sha256)throw new Error('Planning catalogue fingerprint mismatch');
 fs.writeFileSync(path.join(generated,dataFile),data);fs.writeFileSync(path.join(generated,manifestFile),m);
}

const {scienceStatus}=await import('./science-status.mjs');
const eventManifest=JSON.parse(fs.readFileSync(path.join(generated,'calendar-manifest.json'),'utf8'));
const engineVersion=JSON.parse(fs.readFileSync(path.join(web,'package.json'),'utf8')).dependencies['astronomy-engine'];
fs.writeFileSync(path.join(generated,'data-status.json'),JSON.stringify(scienceStatus(manifest,overlayManifest,eventManifest,engineVersion)));
const {verifyBrand}=await import('./verify-brand.mjs');await verifyBrand();
const {stageOffline}=await import("./stage-offline.mjs");await stageOffline(web);
