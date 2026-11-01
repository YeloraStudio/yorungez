"use client";
import DateField from './ui/DateField';
import {useEffect,useState} from 'react';import {Temporal} from '@js-temporal/polyfill';
import {planningText} from '../lib/planning-text.ts';import {messages} from '../lib/i18n.ts';
import type {ObservingPlan} from '../lib/sky/planning.ts';import {intervalInstant} from '../lib/sky/planning-navigation.ts';import type {Language,ObserverContext} from '../lib/sky/types.ts';
export default function TonightPanel({language,context,zone,locationLabel,onNavigate,onCompass,onTerm}:{language:Language;context:ObserverContext;zone:string;locationLabel:string;onNavigate:(id:string,instant:string)=>void;onCompass:()=>void;onTerm:(id:string)=>void}){
 const t=planningText[language],[date,setDate]=useState(()=>Temporal.Instant.from(context.instantUtc).toZonedDateTimeISO(zone).toPlainDate().toString()),[plan,setPlan]=useState<ObservingPlan|null>(null),[error,setError]=useState(false),[attempt,setAttempt]=useState(0);
 useEffect(()=>{let alive=true;setPlan(null);setError(false);let worker:Worker;try{worker=new Worker(new URL('../lib/sky/planning.worker.ts',import.meta.url),{type:'module'})}catch{setError(true);return}const timer=setTimeout(()=>{worker.terminate();if(alive)setError(true)},12000);
  worker.onmessage=e=>{clearTimeout(timer);if(alive){if(e.data.type==='plan')setPlan(e.data.plan);else setError(true)}worker.terminate()};worker.onerror=()=>{clearTimeout(timer);worker.terminate();if(alive)setError(true)};worker.postMessage({context:{latitude:context.latitude,longitude:context.longitude,elevationMeters:context.elevationMeters},zone,date});return()=>{alive=false;clearTimeout(timer);worker.terminate()};
 },[context.latitude,context.longitude,context.elevationMeters,zone,date,attempt]);
 const time=(v:string|null)=>v?new Intl.DateTimeFormat(language,{timeZone:zone,hour:'2-digit',minute:'2-digit',hourCycle:'h23'}).format(new Date(v)):t.missing;
 const move=(n:number)=>setDate(d=>Temporal.PlainDate.from(d).add({days:n}).toString());
 return <section className="observing-panel">
  <div className="plan-date"><button type="button" aria-label={t.previous} disabled={date<="2000-01-02"} onClick={()=>move(-1)}>‹</button><DateField label={t.date} value={date} onChange={setDate} language={language} min="2000-01-02" max="2035-12-30"/><button type="button" aria-label={t.next} disabled={date>="2035-12-30"} onClick={()=>move(1)}>›</button></div>
  <p className="muted compact">{locationLabel}<br/>{zone}</p><p className="muted">{t.help}</p>
  {!plan&&!error&&<p role="status">{t.loading}</p>}{error&&<p role="alert">{t.error} <button className="inline-term" onClick={()=>setAttempt(a=>a+1)}>{t.retry}</button></p>}
  {plan&&<>{plan.nightState!=="ordinary"&&<p className="conditions-note" role="status">{plan.nightState==="no-night"?t.noNight:plan.nightState==="polar-night"?t.polarNight:t.partialNight}</p>}<p className="plan-range">{new Intl.DateTimeFormat(language,{timeZone:zone,dateStyle:"medium"}).format(new Date(plan.startUtc))} – {new Intl.DateTimeFormat(language,{timeZone:zone,dateStyle:"medium"}).format(new Date(plan.endUtc))}</p><div className="sun-times"><div><small>{t.sunset}</small><strong>{time(plan.sunsetUtc)}</strong></div><div><small>{t.sunrise}</small><strong>{time(plan.sunriseUtc)}</strong></div></div><h3>{t.solar}</h3>
   <div className="timeline-axis"><span/>{Array.from({length:5},(_,i)=><span key={i}>{time(new Date(Date.parse(plan.startUtc)+(Date.parse(plan.endUtc)-Date.parse(plan.startUtc))*i/4).toISOString())}</span>)}</div>
   {plan.rows.map(row=><div className="timeline-row" key={row.id}><strong>{messages[language].celestialNames[row.id as keyof typeof messages.tr.celestialNames]}</strong><div className="time-lane">{row.intervals.length?row.intervals.map((interval,i)=>{
    const begin=Date.parse(plan.startUtc),duration=Date.parse(plan.endUtc)-begin,start=Date.parse(interval.startUtc),end=Date.parse(interval.endUtc),label=`${messages[language].celestialNames[row.id as keyof typeof messages.tr.celestialNames]} · ${time(interval.startUtc)}–${time(interval.endUtc)} · ${t.apply}`;
    return <button key={i} className={`time-interval body-${row.id}`} aria-label={label} style={{left:`${(start-begin)/duration*100}%`,width:`${Math.max(.5,(end-start)/duration*100)}%`}} onClick={e=>{
     const rect=e.currentTarget.getBoundingClientRect(),fraction=e.detail===0?null:(e.clientX-rect.left)/rect.width;onNavigate(row.id,intervalInstant(interval,row.bestInstantUtc,fraction));
    }}><span style={start>begin+duration*.7?{left:"auto",right:0}:undefined}>{time(interval.startUtc)}–{time(interval.endUtc)}</span></button>;
   }):<span className="no-interval">—</span>}</div></div>)}
   <details><summary>{t.horizonModel}</summary><button className="inline-term" onClick={()=>onTerm("rise-set")}>{t.horizonModel} ⓘ</button><p className="muted compact">{t.definition}</p><a href="https://github.com/cosinekitty/astronomy/tree/v2.1.19" target="_blank" rel="noreferrer">Astronomy Engine 2.1.19 ↗</a></details>
  </>}
  <p className="conditions-note">{t.conditions}</p><button className="secondary-button" onClick={onCompass}>{t.compass}</button><p className="muted compact">{t.compassHelp}</p>
 </section>;
}
