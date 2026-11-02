"use client";
import {useEffect,useId,useMemo,useRef,useState} from 'react';
import {glossaryText,normalizeTerm,searchTerms,termAnchor,termHref,termIdFromHash} from '../lib/glossary.ts';
import type {BilingualTerm} from '../lib/glossary.ts';
import type {Language} from '../lib/sky/types.ts';
export default function GlossaryBrowser({terms,language,initialTermId='',standalone=false}:{terms:readonly BilingualTerm[];language:Language;initialTermId?:string;standalone?:boolean}){
 const t=glossaryText[language],id=useId(),root=useRef<HTMLDivElement>(null),input=useRef<HTMLInputElement>(null),Heading=standalone?'h2':'h3';
 const [query,setQuery]=useState(''),[selected,setSelected]=useState<string|null>(initialTermId||null),[missing,setMissing]=useState(false);
 useEffect(()=>{
  if(!standalone)return;
  const read=(resetQuery:boolean)=>{const hash=window.location.hash,termId=termIdFromHash(hash),found=terms.some(term=>term.id===termId);setSelected(found?termId:null);setMissing(Boolean(hash)&&!found);if(resetQuery||hash)setQuery('')};
  const changed=()=>read(true);read(false);window.addEventListener('hashchange',changed);return()=>window.removeEventListener('hashchange',changed);
 },[terms,standalone]);
 useEffect(()=>{
  if(!standalone||!selected)return;
  const frame=requestAnimationFrame(()=>root.current?.querySelector<HTMLElement>('[data-selected="true"] .term-heading')?.focus());return()=>cancelAnimationFrame(frame);
 },[selected,standalone]);
 const matches=useMemo(()=>!standalone&&selected?terms.filter(term=>term.id===selected):searchTerms(terms,query,language),[terms,query,language,selected,standalone]);
 function search(value:string){setQuery(value);setSelected(null);setMissing(false);if(standalone&&window.location.hash)window.history.replaceState(null,'',window.location.pathname)}
 return <div ref={root} className="glossary-browser">
  {standalone?<nav className="glossary-language" aria-label={t.languages}>{(['en','tr'] as const).map(lang=><a key={lang} href={termHref(lang,selected)} hrefLang={lang} lang={lang} aria-current={lang===language?'page':undefined}>{lang==='en'?'English':'Türkçe'}</a>)}</nav>:<a className="glossary-full" href={termHref(language,selected)} target="_blank" rel="noopener noreferrer">{t.full} ↗ <small>({t.newTab})</small></a>}
  <div className="glossary-search"><label htmlFor={id+'-search'}>{t.search}</label><div><input ref={input} id={id+'-search'} type="search" autoComplete="off" value={query} onChange={e=>search(e.target.value)} aria-describedby={id+'-help'}/>{query&&<button type="button" className="secondary-button" onClick={()=>{search('');input.current?.focus()}}>{t.clear}</button>}</div><p id={id+'-help'} className="muted">{t.searchHelp}</p></div>
  {missing&&<p role="status" className="conditions-note">{t.missing}</p>}
  {!standalone&&selected&&<button type="button" className="secondary-button" onClick={()=>{search('');input.current?.focus()}}>{t.all}</button>}
  <p className="muted glossary-count" role="status">{t.count}: {new Intl.NumberFormat(language).format(matches.length)}</p>
  {!terms.length?<p role="status">{t.unavailable}</p>:!matches.length?<p>{t.empty}</p>:<div className="term-list">{matches.map(term=>{const content=term.translations[language],aliases=content.aliases.filter(alias=>![normalizeTerm(content.name),normalizeTerm(term.abbreviation??'')].includes(normalizeTerm(alias)));return <article key={term.id} id={termAnchor(term.id)} className="term-entry" data-selected={selected===term.id} aria-labelledby={id+'-'+term.id}>
   <Heading className="term-heading" id={id+'-'+term.id} tabIndex={-1}>{content.name}{term.abbreviation&&<small>{term.abbreviation}</small>}</Heading><p>{content.definition}</p>
   {aliases.length>0&&<p className="muted glossary-aliases">{t.aliases}: {aliases.join(', ')}</p>}
   <div className="term-links"><a href={standalone?'#'+termAnchor(term.id):termHref(language,term.id)} target={standalone?undefined:'_blank'} rel={standalone?undefined:'noopener noreferrer'} aria-label={`${t.link}: ${content.name}${standalone?'':' · '+t.newTab}`}>{t.link} ↗</a><ul aria-label={t.sources}>{term.sources.map((source,index)=><li key={source}><a href={source} target="_blank" rel="noopener noreferrer" aria-label={`${t.sources} ${index+1}: ${content.name} · ${new URL(source).hostname} · ${t.newTab}`}>{new URL(source).hostname} ↗</a></li>)}</ul></div>
  </article>})}</div>}
 </div>;
}
