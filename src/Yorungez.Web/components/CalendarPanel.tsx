"use client";
import SelectField from './ui/SelectField';
import {useEffect,useState} from 'react';import {Temporal} from '@js-temporal/polyfill';
import {planningText} from '../lib/planning-text.ts';import {messages} from '../lib/i18n.ts';
import { eventNames, monthlyObservingTitle, observingAround, weatherBodies, type ObservingSelection } from '../lib/observing-opportunities.ts';
import type {Language} from '../lib/sky/types.ts';import type {CalendarEvent} from '../lib/server/planning-catalog.ts';
export default function CalendarPanel({language,zone,instant,onNavigate,onTerm,onObserve}:{language:Language;zone:string;instant:string;onNavigate:(id:string,time:string)=>void;onTerm:(id:string)=>void;onObserve:(selection:ObservingSelection)=>void}){
 const [localEvents,setLocalEvents]=useState<{monthKey:string;events:{id:string;peakUtc:string;sourceUrl:string}[];failed:boolean}|null>(null);
 const initial=Temporal.Instant.from(instant).toZonedDateTimeISO(zone),[year,setYear]=useState(initial.year),[month,setMonth]=useState(initial.month),[events,setEvents]=useState<CalendarEvent[]|null>(null),[error,setError]=useState(false),[attempt,setAttempt]=useState(0),t=planningText[language];
 useEffect(()=>{const controller=new AbortController();setEvents(null);setError(false);fetch("/pwa/calendar.json",{signal:AbortSignal.any([controller.signal,AbortSignal.timeout(10000)])}).then(r=>{if(!r.ok)throw new Error();return r.json()}).then(data=>{if(controller.signal.aborted)return;if(!Array.isArray(data.events))throw new Error();setEvents(data.events.filter((e:CalendarEvent)=>{const d=Temporal.Instant.from(e.instantUtc).toZonedDateTimeISO(zone);return d.year===year&&d.month===month}))}).catch(()=>{if(!controller.signal.aborted)setError(true)});return()=>controller.abort();},[year,month,zone,attempt]);
 const monthKey=year+'-'+month;
 useEffect(()=>{
  const controller=new AbortController();
  fetch('/api/observing-opportunities?year='+year+'&month='+month,{signal:controller.signal,cache:'no-store'}).then(r=>{
   if(!r.ok)throw new Error('observing calendar');
   return r.json();
  }).then(data=>{
   if(!controller.signal.aborted&&Array.isArray(data))setLocalEvents({monthKey,events:data,failed:false});
  }).catch(()=>{if(!controller.signal.aborted)setLocalEvents({monthKey,events:[],failed:true})});
  return()=>controller.abort();
 },[year,month,monthKey]);
 const monthEvents=localEvents?.monthKey===monthKey?localEvents.events.filter(e=>{
  const d=Temporal.Instant.from(e.peakUtc).toZonedDateTimeISO(zone);
  return d.year===year&&d.month===month;
 }):[];
 const selectedMonth=new Intl.DateTimeFormat(language,{month:'long',year:'numeric',timeZone:'UTC'}).format(new Date(Date.UTC(year,month-1,1)));
 const localDate=new Intl.DateTimeFormat(language,{day:'numeric',timeZone:zone});
 const localMonth=new Intl.DateTimeFormat(language,{month:'short',timeZone:zone});
 const localTime=new Intl.DateTimeFormat(language,{timeZone:zone,dateStyle:'medium',timeStyle:'short'});
 const utcTime=new Intl.DateTimeFormat(language,{timeZone:'UTC',dateStyle:'medium',timeStyle:'short'});
 function dateMark(instantUtc:string){
  const date=new Date(instantUtc);
  return <span className="planning-date-mark" aria-hidden="true"><strong>{localDate.format(date)}</strong><small>{localMonth.format(date)}</small></span>;
 }
 return <section className="calendar-panel planning-styled">
  <div className="planning-intro planning-calendar-intro">
   <strong>{selectedMonth}</strong>
   <p>{t.calendarHelp}</p>
   <button type="button" className="primary-button" onClick={()=>onObserve({monthly:true})}>{monthlyObservingTitle[language]}</button>
   <p className="planning-image-credit"><a href="https://commons.wikimedia.org/wiki/File:FullMoon2010.jpg" target="_blank" rel="noreferrer">
    {language==='tr'?'Ay arşiv fotoğrafı':'Moon archive image'} · Gregory H. Revera · CC BY-SA 3.0
   </a></p>
  </div>
  <div className="planning-picker">
  <button className="inline-term" onClick={()=>onTerm("moon-phase")}>{language==="tr"?"Ay evreleri":"Moon phases"} ⓘ</button><div className="calendar-selects"><SelectField language={language} label={t.month} value={String(month)} onChange={v=>setMonth(Number(v))} options={Array.from({length:12},(_,i)=>({value:String(i+1),label:new Intl.DateTimeFormat(language,{month:'long',timeZone:'UTC'}).format(new Date(Date.UTC(2026,i,1)))}))}/><SelectField language={language} label={t.year} value={String(year)} onChange={v=>setYear(Number(v))} searchable options={Array.from({length:36},(_,i)=>({value:String(2000+i),label:String(2000+i)}))}/></div><p className="muted compact">{zone} · UTC</p></div>
  {!events&&!error&&<p role="status">{messages[language].loading}</p>}{error&&<p role="alert">{t.calendarError} <button className="inline-term" onClick={()=>setAttempt(a=>a+1)}>{t.retry}</button></p>}
  {events?.length===0&&monthEvents.length===0&&<p>{t.empty}</p>}{events?.map(e=>{const kind=t.eventKinds[e.kind as keyof typeof t.eventKinds]??e.kind,title=['opposition','inferior-conjunction','superior-conjunction','greatest-elongation'].includes(e.kind)?`${messages[language].celestialNames[e.targetId as keyof typeof messages.tr.celestialNames]} · ${kind}`:kind;return <article className="calendar-event planning-event" data-kind={e.targetId==='moon'?'lunar':e.targetId==='sun'?'solar':'planet'} key={e.id}>
   <button type="button" className="planning-event-heading" onClick={()=>onNavigate(e.targetId,e.instantUtc)}>
    {dateMark(e.instantUtc)}
    <span><strong>{title}</strong><time dateTime={e.instantUtc}>{localTime.format(new Date(e.instantUtc))}</time><small>{utcTime.format(new Date(e.instantUtc))} UTC</small></span>
   </button>{e.kind!=='new-moon'&&!e.kind.endsWith('conjunction')&&weatherBodies.includes(e.targetId)&&<button type="button" className="inline-term" onClick={()=>onObserve(observingAround(e.targetId,e.instantUtc))}>{language==="tr"?"Konumumdan görülebilir mi?":"Could I see it from here?"}</button>}<details><summary>{t.source} · {e.sourceId==='usno'?t.verified:t.calculated}</summary><p className="muted compact">{e.sourceId==='usno'?`USNO · Astronomy Engine 2.1.19 · Δ ${e.referenceDeltaSeconds?.toFixed(1)} s`:'Astronomy Engine 2.1.19'} · <a href={e.sourceId==='usno'?'https://aa.usno.navy.mil/data/MoonPhases':'https://github.com/cosinekitty/astronomy/tree/v2.1.19'} target="_blank" rel="noreferrer">{t.source} ↗</a></p></details></article>})}{monthEvents.map(e=><article className="forecast-card planning-event" data-kind={e.id.endsWith('-lunar')?'lunar':'meteor'} key={e.id+e.peakUtc}>
   <div className="planning-event-heading">
    {dateMark(e.peakUtc)}
    <span><strong>{eventNames[language][e.id]}</strong><time dateTime={e.peakUtc}>{localTime.format(new Date(e.peakUtc))}</time><small>{utcTime.format(new Date(e.peakUtc))} UTC</small></span>
   </div>
   <button type="button" className="secondary-button" onClick={()=>onObserve(observingAround(e.id.endsWith('-lunar')?'lunar-eclipse':e.id,e.peakUtc,e.id.endsWith('-lunar')?8:18))}>{language==="tr"?"Konumumdan görülebilir mi?":"Could I see it from here?"}</button>
   <p><a href={e.sourceUrl} target="_blank" rel="noreferrer">{t.source} ↗</a></p>
  </article>)}
  {localEvents?.monthKey===monthKey&&localEvents.failed&&<p className="muted">{language==="tr"?"Ay tutulması ve meteor yağmuru listesi alınamadı.":"Lunar eclipse and meteor shower dates are unavailable."}</p>}
  <p className="conditions-note">{t.global}</p>
 </section>;
}
