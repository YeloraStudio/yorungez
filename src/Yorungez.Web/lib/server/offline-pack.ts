import fs from 'node:fs/promises';
import path from 'node:path';
export async function offlineArtifact(name:'worker.js'|'pack.json',type:string){
 try{const dist=process.env.YORUNGEZ_BUILD_DIR==='.next-preview'?'.next-preview':'.next';const bytes=await fs.readFile(path.join(process.cwd(),dist,'yorungez-pwa',name));return new Response(bytes,{headers:{'Content-Type':type,'Cache-Control':'no-store, no-cache, must-revalidate'}})}
 catch{return new Response('Public offline pack is not built.',{status:503,headers:{'Cache-Control':'no-store'}})}
}
