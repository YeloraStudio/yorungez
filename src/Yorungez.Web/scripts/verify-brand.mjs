import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
const web=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..'),root=path.resolve(web,'../..');
const sha=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
export async function verifyBrand(){
 const provenance=JSON.parse(await fs.readFile(path.join(root,'data/branding/provenance.json'),'utf8'));
 const manifest=JSON.parse(await fs.readFile(path.join(root,'data/branding/assets.json'),'utf8'));
 for(const asset of [...provenance.sources,manifest.email])if(sha(await fs.readFile(path.join(root,asset.file)))!==asset.sha256)throw new Error('Brand source fingerprint mismatch: '+asset.file);
 for(const asset of Object.values(manifest.assets)){
  if(!/^\/brand\/[a-z0-9.-]+$/.test(asset.src)||!asset.src.includes(asset.sha256.slice(0,12)))throw new Error('Invalid brand asset URL');
  const bytes=await fs.readFile(path.join(web,'public',asset.src));
  if(sha(bytes)!==asset.sha256||bytes.length!==asset.bytes)throw new Error('Brand export fingerprint mismatch: '+asset.src);
 }
 for(const [file,role] of [['favicon.svg','faviconSvg'],['favicon.ico','faviconIco']])if(sha(await fs.readFile(path.join(web,'public',file)))!==manifest.assets[role].sha256)throw new Error('Favicon alias mismatch');
 return manifest;
}
