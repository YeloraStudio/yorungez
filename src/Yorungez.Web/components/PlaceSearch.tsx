"use client";
import {useEffect,useRef,useState} from 'react';import {planningText} from '../lib/planning-text.ts';
import type {Language} from '../lib/sky/types.ts';import type {Place} from '../lib/server/planning-catalog.ts';
export function placeTitle(p:Place){return [p.name,p.region&&p.region!==p.name?p.region:'',p.country].filter(Boolean).join(', ')}
export default function PlaceSearch({language,onPick}:{language:Language;onPick:(p:Place)=>void}){
 const t=planningText[language],[rows,setRows]=useState<Place[]>([]),[state,setState]=useState('idle'),controller=useRef<AbortController|null>(null);
 useEffect(()=>()=>controller.current?.abort(),[]);
 return <section className="place-search"><form onSubmit={e=>{e.preventDefault();const query=String(new FormData(e.currentTarget).get('placeQuery')??'').trim();controller.current?.abort();const c=new AbortController();controller.current=c;setState('loading');setRows([]);
  fetch('/api/location/places',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({query}),cache:'no-store',signal:AbortSignal.any([c.signal,AbortSignal.timeout(10000)])}).then(r=>{if(!r.ok)throw new Error();return r.json()}).then(data=>{if(c.signal.aborted)return;setRows(data.places);setState(data.places.length?'ready':'error')}).catch(()=>{if(!c.signal.aborted)setState('error')});
 }}><label>{t.placeSearch}<input name="placeQuery" type="search" minLength={2} maxLength={120} required placeholder={language==='tr'?'İstanbul, London, Sydney…':'Istanbul, London, Sydney…'}/></label><button className="secondary-button" disabled={state==='loading'}>{t.search}</button></form>{state==='loading'&&<p className="muted" role="status">{t.placeLoading}</p>}{state==='error'&&<p className="muted" role="status">{t.placeError}</p>}
  <div className="place-results">{rows.map(p=><button key={p.id} className="secondary-button" onClick={()=>{onPick(p);setRows([]);setState('idle')}}>{placeTitle(p)}</button>)}</div><p className="muted compact">{t.placeHelp} <a href="https://www.geonames.org/" target="_blank" rel="noreferrer">GeoNames · CC BY 4.0 ↗</a></p>
 </section>;
}
