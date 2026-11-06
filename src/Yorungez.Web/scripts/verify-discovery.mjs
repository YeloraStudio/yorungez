import fs from 'node:fs/promises';
import path from 'node:path';
import assert from 'node:assert/strict';
const web=process.cwd(),dist=path.join(web,process.env.YORUNGEZ_BUILD_DIR==='.next-preview'?'.next-preview':'.next');
const content=JSON.parse(await fs.readFile(path.resolve(web,'../../data/knowledge/guides.json'),'utf8'));
const paths=['','/library','/terms','/about','/mobile','/privacy',...content.guides.map(g=>`/library/${g.slug}`)];
const sitemap=await fs.readFile(path.join(dist,'server/app/sitemap.xml.body'),'utf8');
assert.equal((sitemap.match(/<loc>/g)||[]).length,paths.length*2);
for(const lang of ['en','tr'])for(const suffix of paths){
 const html=await fs.readFile(path.join(dist,'server/app',lang+suffix+'.html'),'utf8');
 assert.ok(html.includes(`<html lang="${lang}"`));
 assert.ok(html.includes(`rel="canonical" href="https://yorungez.com/${lang}${suffix}"`),`Canonical missing: ${lang}${suffix}`);
 for(const [alternate,target] of [['en','en'],['tr','tr'],['x-default','en']])assert.match(html,new RegExp(`rel="alternate" hrefLang="${alternate}" href="https://yorungez.com/${target}${suffix}"`,'i'));
 assert.ok(html.includes('name="description"'));assert.ok(html.includes('property="og:image"'));assert.ok(html.includes('name="twitter:card"'));
 assert.ok(html.includes('name="msvalidate.01"'));assert.ok(!html.includes('content="noindex'));
 assert.ok(sitemap.includes(`<loc>https://yorungez.com/${lang}${suffix}</loc>`));
 if(suffix.startsWith('/library/')){
  const schema=[...html.matchAll(/<script type="application\/ld\+json">([^<]+)<\/script>/g)].map(m=>JSON.parse(m[1]));
  assert.ok(schema.some(s=>s['@type']==='Article'&&s.inLanguage===lang&&s.citation.length>=1));
  assert.ok(html.includes('https://')&&html.includes('<article'));
 }
}
assert.ok(!sitemap.includes('/account/')&&!sitemap.includes('/api/')&&!sitemap.includes('/lab/'));
const robots=await fs.readFile(path.join(dist,'server/app/robots.txt.body'),'utf8');
for(const privatePath of ['/api/','/en/account/','/tr/account/','/en/lab/','/tr/lab/'])assert.ok(robots.includes(`Disallow: ${privatePath}`));
for(const guide of content.guides)for(const lang of ['en','tr']){assert.ok(guide.title[lang]&&guide.summary[lang]);assert.ok(guide.sections.length>=3&&guide.sections.every(s=>s.heading[lang]&&s.text[lang]));assert.ok(guide.sources.every(s=>s.url.startsWith('https://')&&s.title));}
console.log(`Verified ${paths.length*2} static EN/TR public pages: canonical/hreflang, share metadata, sourced Article schema, sitemap and private-path exclusions.`);
