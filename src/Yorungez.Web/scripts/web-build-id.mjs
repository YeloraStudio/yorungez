import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
// Stable across backend/native-only deployments. Include every Web runtime input,
// including staged scientific/public assets, but never private environment values.
export async function webBuildId(web){
 const hash=crypto.createHash('sha256');
 async function visit(file){
  const stat=await fs.stat(file).catch(()=>null);if(!stat)return;
  if(stat.isDirectory()){for(const entry of (await fs.readdir(file)).sort())await visit(path.join(file,entry));return;}
  hash.update(path.relative(web,file).replaceAll('\\','/'));hash.update('\0');hash.update(await fs.readFile(file));hash.update('\0');
 }
 for(const name of ['app','components','lib','scripts','generated','public','package.json','package-lock.json','next.config.ts','proxy.ts','tsconfig.json'])await visit(path.join(web,name));
 // Direct imports outside the Web tree are public canonical content.
 for(const name of ['knowledge','branding/assets.json'])await visit(path.resolve(web,'../../data',name));
 return 'web-'+hash.digest('hex').slice(0,24);
}
