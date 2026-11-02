"use client";
import { useEffect, useState } from "react";
import ObjectVisual,{visualText} from "./ObjectVisual";
import photos from "../generated/object-photos.json";
import type {ArchiveImage} from "../lib/object-media.ts";
import { messages } from "../lib/i18n.ts";
import { explorerText } from "../lib/explorer-text.ts";
import { objectCategory } from "../lib/sky/frame-contract.ts";
import type { SkyFrame } from "../lib/sky/frame-contract.ts";
import type { Language, SkyCatalog } from "../lib/sky/types.ts";
export interface SelectedObject {id:string;name:string;kind:"star"|"solar"|"constellation"|"deepSky";index:number}
interface Article {title:string;extract:string;url:string;revision?:number;fetchedAtUtc:string;license:string;licenseUrl:string;image:null|{url:string;sourceUrl:string;credit:string;license:string;licenseUrl:string}}
export default function ObjectCard({object,catalog,frame,language,onClose,onFocus,onTerm,onCompass,onNotebook,compact,onExpand}:{object:SelectedObject;catalog:SkyCatalog;frame:SkyFrame|null;language:Language;onClose:()=>void;onFocus:()=>void;onTerm:(id:string)=>void;onCompass:()=>void;onNotebook:()=>void;compact:boolean;onExpand:()=>void}){
 const t={...messages[language],...explorerText[language]},[article,setArticle]=useState<Article|null>(null),[state,setState]=useState("loading"),[attempt,setAttempt]=useState(0);
 useEffect(()=>{const controller=new AbortController();setArticle(null);setState("loading");
  fetch(`/api/objects/${encodeURIComponent(object.id)}?lang=${language}`,{signal:AbortSignal.any([controller.signal,AbortSignal.timeout(12000)])}).then(r=>{if(!r.ok)throw new Error(r.status===404?"missing":"unavailable");return r.json()}).then(data=>{if(!controller.signal.aborted){setArticle(data);setState("ready")}}).catch(error=>{if(!controller.signal.aborted)setState(error instanceof Error&&error.message==="missing"?"missing":"error")});return()=>controller.abort();
 },[object.id,language,attempt]);
 const star=object.kind==="star"?catalog.stars[object.index]:null,dso=object.kind==="deepSky"?catalog.deepSky?.find(o=>o.id===object.id):null;
 const solar=object.kind==="solar"?object.index-catalog.stars.length:-1;
 const az=frame?.angles[object.index*2]??NaN,alt=frame?.angles[object.index*2+1]??NaN;
 const format=(n:number,digits=1)=>Number.isFinite(n)?new Intl.NumberFormat(language,{maximumFractionDigits:digits,minimumFractionDigits:digits}).format(n):"—";
 const kind=dso?(t.dsoTypes[dso.type as keyof typeof t.dsoTypes]??t.deepSky):t[objectCategory(object.kind,object.id)];
 const v=visualText[language];
 const shortExtract=article?(article.extract.length>180?article.extract.slice(0,180).replace(/\s+\S*$/,"")+"…":article.extract):"";
 return <section id="object-panel" className={`object-card glass${compact?" compact-card":""}`} aria-labelledby="object-heading" data-object-id={object.id}>
  <div className="card-heading"><div><span className="eyebrow">{kind}</span><h2 id="object-heading" tabIndex={-1}>{object.name}</h2><small className="catalog-id">{star?.hip?`HIP ${star.hip} · `:""}{dso?.designation??object.id}</small></div><button className="icon-button" aria-label={t.closeCard} onClick={onClose}>×</button></div>
  {compact&&<button className="card-restore secondary-button" onClick={onExpand}>{t.more} ↗</button>}
  <ObjectVisual object={object} catalog={catalog} frame={frame} language={language} image={(photos as Record<string,ArchiveImage>)[object.id]??article?.image??null}/>
  <div className="object-about">  {state==="loading"&&<p className="muted" role="status">{t.articleLoading}</p>}
  {state==="error"&&<p className="muted">{t.articleUnavailable} <button className="inline-term" onClick={()=>setAttempt(a=>a+1)}>{t.retry}</button></p>}
{state==="missing"&&<p className="muted">{v.noArticle}</p>}{article&&<><p className="object-summary">{shortExtract}</p><a className="wiki-reference" href={`${article.url}${article.revision?`?oldid=${article.revision}`:""}`} target="_blank" rel="noreferrer">{t.wikipedia} ↗</a></>}</div>
  <p className={`horizon-status ${Number.isFinite(alt)?alt>0?"above":"below":"pending"}`}>{!Number.isFinite(alt)?v.pending:object.kind==="constellation"?t.schematic:alt>0?t.above:t.below}</p>
  <div className="coordinate-cards"><div><button onClick={()=>onTerm("azimuth")}>{t.azimuth} ⓘ</button><strong>{frame?.canPublishAzimuth?format(az)+"°":"—"}</strong></div><div><button onClick={()=>onTerm("altitude")}>{t.altitude} ⓘ</button><strong>{Number.isFinite(alt)?format(alt)+"°":"—"}</strong></div></div>
  <button className="primary-button focus-object" onClick={onFocus} disabled={!frame?.canPublishAzimuth}>{t.focus}<span>↗</span></button>
  <div className="object-secondary-actions"><button className="secondary-button compass-object" onClick={onCompass}>{language==="tr"?"Yön bul · Pusula":"Find direction · Compass"}</button><button className="secondary-button compass-object" onClick={onNotebook}>{language==="tr"?"Defterime ekle":"Add to my notebook"}</button></div>
  {article&&<details className="encyclopedia"><summary>{t.more}</summary><p>{article.extract}</p><p className="source-credit">{t.articleCredit} · <a href={article.licenseUrl} target="_blank" rel="noreferrer">{article.license}</a><br/>{t.sourceDate}: {new Intl.DateTimeFormat(language,{dateStyle:"medium",timeZone:"UTC"}).format(new Date(article.fetchedAtUtc))}</p></details>}
  <details className="physical-details"><summary>{language==="tr"?"Konum ve fiziksel bilgiler":"Position and physical information"}</summary><dl className="object-facts">
   {(star||dso)&&<><div><dt><button onClick={()=>onTerm("magnitude")}>{t.magnitude} ⓘ</button></dt><dd>{format(star?.magnitude??dso?.magnitude??NaN,2)}</dd></div><div className="fact-caption"><button onClick={()=>onTerm("j2000")}>{t.epoch} ⓘ</button></div><div><dt>{t.ra}</dt><dd>{format(star?.raHoursJ2000??dso!.raHoursJ2000,4)} h</dd></div><div><dt>{t.dec}</dt><dd>{format(star?.decDegreesJ2000??dso!.decDegreesJ2000,4)}°</dd></div></>}
   {star&&<div><dt><button onClick={()=>onTerm("light-year")}>{t.distance} ⓘ</button></dt><dd>{star.distanceParsecs?`${format(star.distanceParsecs*3.26156)} ${t.lightYears}`:t.unknown}</dd></div>}
   {solar>=0&&frame&&<><div><dt><button onClick={()=>onTerm("astronomical-unit")}>{t.earthDistance} ⓘ</button></dt><dd>{format(frame.solarEquatorial[solar*3+2],6)} {t.au}</dd></div><div className="fact-caption">{t.ofDate}</div><div><dt>{t.ra}</dt><dd>{format(frame.solarEquatorial[solar*3],4)} h</dd></div><div><dt>{t.dec}</dt><dd>{format(frame.solarEquatorial[solar*3+1],4)}°</dd></div></>}
  </dl><p className="muted compact">{t.modelHelp}</p><p className="source-credit">{t.objectSources}</p></details>
  <p className="conditions-note">ⓘ {t.conditions}<span>{t.conditionsHelp}</span></p>
 </section>;
}
