import assert from 'node:assert/strict';
import test from 'node:test';
import fs from 'node:fs/promises';
import sharp from 'sharp';
import {verifyBrand} from '../scripts/verify-brand.mjs';

test('brand exports retain their source fingerprints, dimensions and self-contained SVGs',async()=>{
 const {assets,email}=await verifyBrand();
 for(const asset of Object.values(assets) as {src:string;width:number;height:number}[]){
  const bytes=await fs.readFile(new URL('../public'+asset.src,import.meta.url));
  if(asset.src.endsWith('.ico')){
   assert.equal(bytes.readUInt16LE(2),1);assert.equal(bytes.readUInt16LE(4),3);
   for(const [i,size] of [16,32,48].entries()){
    const pos=6+i*16,length=bytes.readUInt32LE(pos+8),offset=bytes.readUInt32LE(pos+12);
    assert.equal(bytes[pos],size);assert.equal(bytes[pos+1],size);
    const m=await sharp(bytes.subarray(offset,offset+length)).metadata();assert.equal(m.width,size);assert.equal(m.height,size);
   }
   continue;
  }
  const m=await sharp(bytes).metadata();assert.equal(m.width,asset.width);assert.equal(m.height,asset.height);
  if(asset.src.endsWith('.svg'))assert.doesNotMatch(bytes.toString(),/<script|<foreignObject|\bon\w+\s*=|(?:href|src)\s*=/i);
 }
 assert.equal(email.width,720);
 assert.notEqual(assets.app512.src,assets.maskable512.src);
 assert.equal(assets.apple180.width,180);
});

test('launcher images are opaque and maskable foreground remains inside the central safe circle',async()=>{
 const {assets}=await verifyBrand();
 for(const key of ['app192','app512','apple180','maskable512']){
  const bytes=await fs.readFile(new URL('../public'+assets[key].src,import.meta.url)),m=await sharp(bytes).metadata();assert.equal(m.hasAlpha,false);
 }
 const {data,info}=await sharp(await fs.readFile(new URL('../public'+assets.maskable512.src,import.meta.url))).removeAlpha().raw().toBuffer({resolveWithObject:true});
 for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++)if(Math.hypot(x+.5-256,y+.5-256)>204.8){
  const offset=(y*info.width+x)*info.channels;assert.deepEqual([...data.subarray(offset,offset+3)],[60,63,67]);
 }
});
