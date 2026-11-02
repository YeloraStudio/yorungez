import assert from 'node:assert/strict';
import test from 'node:test';
import fs from 'node:fs';
import {glossaryText,normalizeTerm,searchTerms,termHref,termIdFromHash} from '../lib/glossary.ts';
import type {BilingualTerm} from '../lib/glossary.ts';
const terms:BilingualTerm[]=JSON.parse(fs.readFileSync(new URL('../../../src/Modules/Catalog/Yorungez.Catalog.Infrastructure/Data/glossary.json',import.meta.url),'utf8'));
test('glossary search finds either language and abbreviations regardless of the displayed language',()=>{
 for(const lang of ['en','tr'] as const){
  assert.equal(searchTerms(terms,'UFUK YÜKSEKLİĞİ',lang)[0]?.id,'altitude');
  assert.equal(searchTerms(terms,'right ascension',lang)[0]?.id,'right-ascension');
  assert.equal(searchTerms(terms,'  yatay   yon ',lang)[0]?.id,'azimuth');
  assert.ok(searchTerms(terms,'UTC',lang).some(t=>t.abbreviation==='UTC'));
  assert.deepEqual(searchTerms(terms,'no-such-astronomical-term',lang),[]);
  const all=searchTerms(terms,' ',lang);assert.equal(all.length,terms.length);assert.equal(new Set(all.map(t=>t.id)).size,terms.length);
 }
 assert.equal(normalizeTerm('IŞIK'),normalizeTerm('ışık'));
});
test('each stable term has a same-language deep link with a validated fragment; malformed links do not throw',()=>{
 for(const term of terms)for(const lang of ['en','tr'] as const){const url=new URL(termHref(lang,term.id),'https://example.test');assert.equal(url.pathname,`/${lang}/terms`);assert.equal(termIdFromHash(url.hash),term.id);assert.equal(url.search,'');}
 for(const hash of ['','#other','#term-','#term-%E0%A4%A','#term-../../account','#term-azimuth?latitude=1'])assert.equal(termIdFromHash(hash),null);
 assert.equal(termHref('en'),'/en/terms');assert.equal(termIdFromHash('#term-not-in-the-catalogue'),'not-in-the-catalogue');
 assert.deepEqual(Object.keys(glossaryText.en).sort(),Object.keys(glossaryText.tr).sort());
});
