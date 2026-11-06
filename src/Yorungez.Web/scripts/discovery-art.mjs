import sharp from 'sharp';
import fs from 'node:fs/promises';
import path from 'node:path';
const web=process.cwd(),out=path.join(web,'public/discovery');
await fs.mkdir(out,{recursive:true});
const {assets}=JSON.parse(await fs.readFile(path.join(web,'../../data/branding/assets.json'),'utf8'));
const logo=await sharp(path.join(web,'public',assets.wordmarkDark.src)).resize({width:480}).png().toBuffer();
const typography=Buffer.from(`<svg width="1200" height="630" xmlns="http://www.w3.org/2000/svg"><rect width="1200" height="630" fill="#3C3F43"/><circle cx="1080" cy="80" r="370" fill="none" stroke="#9EA1A6" stroke-width="1" opacity=".3"/><circle cx="1080" cy="80" r="450" fill="none" stroke="#C9B6A6" stroke-width="1" opacity=".2"/><rect x="80" y="324" width="70" height="6" rx="3" fill="#8B2333"/><text x="80" y="410" font-family="sans-serif" font-size="49" font-weight="bold" fill="#F7F1E6">Your sky. Your discoveries.</text><text x="80" y="464" font-family="sans-serif" font-size="25" fill="#C9B6A6">Live sky · Astronomy guides · Open source</text><text x="80" y="560" font-family="sans-serif" font-size="21" fill="#F7F1E6">yorungez.com</text></svg>`);
await sharp(typography).composite([{input:logo,left:70,top:90}]).png().toFile(path.join(out,'yorungez-social.png'));
