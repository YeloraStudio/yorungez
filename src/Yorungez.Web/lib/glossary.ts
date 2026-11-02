import type {Language} from './sky/types.ts';
export interface BilingualTerm {id:string;abbreviation:string|null;sources:string[];translations:Record<Language,{name:string;definition:string;aliases:string[]}>}
export const glossaryText={
 en:{title:'Terms and abbreviations',intro:'Understand the sky, one term at a time. Plain-language explanations from the same sourced glossary used on the map.',search:'Search the glossary',searchHelp:'Search in English or Turkish, by name, abbreviation or alternative name.',clear:'Clear search',all:'Show all terms',empty:'No matching terms. Try an abbreviation or a name in either language.',unavailable:'The glossary is not available yet. Close this panel and retry loading the sky.',missing:'This term link does not match the glossary. You can search all terms below.',aliases:'Also known as',sources:'Sources',link:'Link to this term',full:'Open the full glossary',newTab:'opens in a new tab',back:'Return to sky',languages:'Glossary language',count:'Terms found'},
 tr:{title:'Terimler ve kısaltmalar',intro:'Gökyüzünü terimleri anlayarak keşfet. Haritada kullanılan aynı kaynaklı sözlükten sade açıklamalar.',search:'Sözlükte ara',searchHelp:'Türkçe veya İngilizce ad, kısaltma ya da alternatif adla ara.',clear:'Aramayı temizle',all:'Tüm terimleri göster',empty:'Eşleşen terim yok. Bir kısaltma veya iki dilden birinde ad dene.',unavailable:'Sözlük henüz hazır değil. Paneli kapatıp gökyüzünü yeniden yüklemeyi dene.',missing:'Bu terim bağlantısı sözlükle eşleşmiyor. Aşağıda tüm terimlerde arama yapabilirsin.',aliases:'Diğer adları',sources:'Kaynaklar',link:'Bu terimin bağlantısı',full:'Sözlüğü ayrı sayfada aç',newTab:'yeni sekmede açılır',back:'Gökyüzüne dön',languages:'Sözlük dili',count:'Bulunan terim'}
} as const;
export const normalizeTerm=(value:string)=>value.normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase().replace(/ı/g,'i');
export function searchTerms(terms:readonly BilingualTerm[],query:string,language:Language):BilingualTerm[]{
 const text=normalizeTerm(query.trim()),tokens=text.split(/\s+/).filter(Boolean),collator=new Intl.Collator(language,{sensitivity:'base',numeric:true});
 const fields=(term:BilingualTerm)=>[term.id,term.abbreviation??'',...Object.values(term.translations).flatMap(t=>[t.name,...t.aliases])].map(normalizeTerm);
 return terms.map(term=>{const names=fields(term);return {term,key:names.join(' '),exact:!!text&&names.includes(text)}})
  .filter(row=>tokens.every(token=>row.key.includes(token)))
  .sort((a,b)=>Number(b.exact)-Number(a.exact)||collator.compare(a.term.translations[language].name,b.term.translations[language].name)||a.term.id.localeCompare(b.term.id)).map(row=>row.term);
}
export const termAnchor=(id:string)=>'term-'+id;
export function termIdFromHash(hash:string):string|null{
 try{return /^#term-([a-z0-9]+(?:-[a-z0-9]+)*)$/.exec(decodeURIComponent(hash))?.[1]??null}catch{return null}
}
export const termHref=(language:Language,id?:string|null)=>`/${language}/terms${id?'#'+termAnchor(id):''}`;
