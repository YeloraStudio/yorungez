"use client";
import { useEffect, useMemo, useRef, useState } from "react";
import dynamic from "next/dynamic";
import SkyMap from "./SkyMap";
import SelectField from "./ui/SelectField";
import DateTimeField from "./ui/DateTimeField";
import ObjectCard from "./ObjectCard";
import TonightPanel from "./TonightPanel";
import {useAccountSession} from "../lib/use-account-session.ts";
import {accountName} from "../lib/account.ts";
import {usePwa} from "../lib/pwa/use-pwa.ts";
import PwaPanel from "./PwaPanel";
import AccountStatus from "./AccountStatus";
import AccountNotebook from "./AccountNotebook";
import type {NotebookLocation} from "../lib/notebook/model.ts";
import {observerAtSavedLocation} from "../lib/notebook/inventory.ts";
import CalendarPanel from "./CalendarPanel";
import PlaceSearch,{placeTitle} from "./PlaceSearch";
import type {Place} from "../lib/server/planning-catalog.ts";
import {planningText} from "../lib/planning-text.ts";
import CompassPanel,{compassText} from "./CompassPanel";
import type { SelectedObject } from "./ObjectCard";
import { messages } from "../lib/i18n.ts";
import { explorerText } from "../lib/explorer-text.ts";
import { SOLAR_IDS, objectCategory } from "../lib/sky/frame-contract.ts";
import type { SkyFrame } from "../lib/sky/frame-contract.ts";
import { SkyWorkerClient } from "../lib/sky/worker-client.ts";
import { loadSkyCatalog } from "../lib/sky/load-catalog.ts";
import { validateContext } from "../lib/sky/validation.ts";
import { normalizedCamera } from "../lib/sky/projection.ts";
import { defaultLayers } from "../lib/sky/layers.ts";
import type { Layers } from "../lib/sky/layers.ts";
import { positionContext } from "../lib/location/position.ts";
import { localInput, localToUtc, timeDraft, validZone } from "../lib/location/time.ts";
import type { Camera, Language, ObserverContext, SkyCatalog } from "../lib/sky/types.ts";
const EarthPicker=dynamic(()=>import("./EarthPicker"),{ssr:false});
function Icon({ name, size = 18 }: { name: string; size?: number }) {
  const paths: Record<string, string> = {
    menu: "M4 6h16M4 12h16M4 18h16",
    search: "m21 21-4.5-4.5M10.5 18a7.5 7.5 0 1 0 0-15 7.5 7.5 0 0 0 0 15Z",
    location: "M20 10c0 6-8 12-8 12S4 16 4 10a8 8 0 1 1 16 0ZM12 7v6M9 10h6",
    clock: "M12 7v5l4 2M22 12a10 10 0 1 1-20 0 10 10 0 0 1 20 0Z",
    layers: "m12 3 10 6-10 6L2 9l10-6ZM2 13l10 6 10-6M2 17l10 6 10-6",
    star: "m12 2 3 6 7 1-5 5 1 8-6-4-6 4 1-8-5-5 7-1 3-6Z",
    close: "m6 6 12 12M6 18 18 6", plus: "M12 5v14M5 12h14", minus: "M5 12h14",
    arrow: "M5 12h14m-6-6 6 6-6 6", compass: "m15 9-2 4-4 2 2-4 4-2ZM22 12a10 10 0 1 1-20 0 10 10 0 0 1 20 0Z",
    moon: "M20 15A9 9 0 0 1 9 4a9 9 0 1 0 11 11Z", book: "M12 5C8 2 4 3 2 4v16c4-2 7-1 10 1 3-2 6-3 10-1V4c-4-2-7-1-10 1Zm0 0v16",
    expand: "M8 3H3v5M16 3h5v5M3 16v5h5M21 16v5h-5", info: "M12 11v6M12 7v.1M22 12a10 10 0 1 1-20 0 10 10 0 0 1 20 0Z"
  };
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d={paths[name] ?? paths.star} /></svg>;
}
interface BilingualTerm {id:string;abbreviation:string|null;sources:string[];translations:Record<Language,{name:string;definition:string;aliases:string[]}>}
const normalize=(value:string)=>value.normalize("NFD").replace(/[\u0300-\u036f]/g,"").replace(/ı/g,"i").toLowerCase();
const initialCamera:Camera={azimuth:180,altitude:14,fieldOfView:105};
const parseCoordinate=(value:string)=>/^[+-]?(?:\d+(?:[.,]\d+)?|[.,]\d+)$/.test(value.trim())?Number(value.trim().replace(",",".")):NaN;
function objectIndex(c:SkyCatalog,id:string){const star=c.stars.findIndex(s=>s.id===id);if(star>=0)return star;const solar=SOLAR_IDS.indexOf(id as typeof SOLAR_IDS[number]);if(solar>=0)return c.stars.length+solar;const pattern=c.constellations.findIndex(s=>s.id===id);if(pattern>=0)return c.stars.length+9+pattern;const dso=c.deepSky?.findIndex(s=>s.id===id)??-1;return dso<0?-1:c.stars.length+9+c.constellations.length+dso;}
export default function SkyExplorer({initialLanguage}:{initialLanguage:Language}){
 const [language,setLanguage]=useState<Language>(initialLanguage),t={...messages[language],...explorerText[language]},p=planningText[language];
 const [catalog,setCatalog]=useState<SkyCatalog|null>(null),[terms,setTerms]=useState<BilingualTerm[]>([]),[frame,setFrame]=useState<SkyFrame|null>(null);
 const [loadState,setLoadState]=useState<"catalog"|"initializing"|"calculating"|"ready"|"error">("catalog"),[fetchError,setFetchError]=useState(false),[fetchAttempt,setFetchAttempt]=useState(0),[computeAttempt,setComputeAttempt]=useState(0);
 const [pwaEnabled,setPwaEnabled]=useState(false);
 useEffect(()=>{if(loadState==="ready")setPwaEnabled(true)},[loadState]);
 const pwa=usePwa(pwaEnabled);
 const [context,setContext]=useState<ObserverContext>({latitude:41.0082,longitude:28.9784,elevationMeters:null,instantUtc:"2026-10-31T00:00:00Z",source:"example"});
 const [mode,setMode]=useState<"live"|"simulation">("live"),[camera,setCamera]=useState(initialCamera),[selected,setSelected]=useState<string|null>(null),[query,setQuery]=useState("");
 const [cardExpanded,setCardExpanded]=useState(true);
 const [layers,setLayers]=useState<Layers>({...defaultLayers}),[layerMenu,setLayerMenu]=useState(false),[fullScreen,setFullScreen]=useState(false),[screenError,setScreenError]=useState(false);
 const [modal,setModal]=useState<"menu"|"location"|"time"|"glossary"|"sources"|"compass"|"tonight"|"calendar"|"notebook"|"offline"|null>(null),[draftLat,setDraftLat]=useState(""),[draftLon,setDraftLon]=useState(""),[draftTime,setDraftTime]=useState(""),[termQuery,setTermQuery]=useState("");
 const [accountEntry,setAccountEntry]=useState<{view:'login'|'register';sequence:number}>({view:'login',sequence:0});
 const account=useAccountSession(language,modal==='menu'||modal==='notebook');
 const [notebookVisited,setNotebookVisited]=useState(false),[notebookSection,setNotebookSection]=useState<"all"|"places">("all");
 const [draftName,setDraftName]=useState(""),[draftElevation,setDraftElevation]=useState(""),[placeHint,setPlaceHint]=useState<{latitude:number;longitude:number;place:Place}|null>(null);
 const [formError,setFormError]=useState(false),[showEarth,setShowEarth]=useState(false),[geoState,setGeoState]=useState("idle");
 const [autoZone,setAutoZone]=useState("Europe/Istanbul"),[zoneOverride,setZoneOverride]=useState<string|null>(null),[zones,setZones]=useState<string[]>(["Europe/Istanbul"]),[zoneState,setZoneState]=useState("loading");
 const [timeBasis,setTimeBasis]=useState<"local"|"UTC">("local"),[occurrence,setOccurrence]=useState<"reject"|"earlier"|"later">("reject");
 const client=useRef<SkyWorkerClient|null>(null),current=useRef(context),focusPending=useRef<string|null>(null),dialog=useRef<HTMLDialogElement>(null),search=useRef<HTMLInputElement>(null),shell=useRef<HTMLDivElement>(null);
 const geoGeneration=useRef(0),geoPending=useRef(false),geoTimer=useRef<ReturnType<typeof setTimeout>|undefined>(undefined);current.current=context;
 const startTime=useRef(0),firstReady=useRef(false),[firstFrameMs,setFirstFrameMs]=useState(0);
 const zone=zoneOverride??(zoneState==="ready"&&zones.length===1?autoZone:"UTC");
 useEffect(()=>{document.documentElement.lang=language;document.title=`yorungez — ${messages[language].sky}`},[language]);
 useEffect(()=>{
  const controller=new AbortController();setLoadState("catalog");setFetchError(false);startTime.current=performance.now();
  loadSkyCatalog(controller.signal).then(snapshot=>{
   setCatalog(snapshot.catalog);setTerms(snapshot.glossary);
  }).catch(()=>{if(!controller.signal.aborted){setFetchError(true);setLoadState("error")}});return()=>controller.abort();
 },[fetchAttempt]);
 useEffect(()=>{
  if(!catalog)return;
  const runner=new SkyWorkerClient(catalog,result=>{setFrame(result);if(!firstReady.current){firstReady.current=true;setFirstFrameMs(Math.round(performance.now()-startTime.current))}
   if(focusPending.current&&result.canPublishAzimuth){const index=objectIndex(catalog,focusPending.current);focusPending.current=null;if(index>=0)setCamera(c=>normalizedCamera({...c,azimuth:result.angles[index*2],altitude:result.angles[index*2+1]}));}
  },setLoadState,()=>new Worker(new URL("../lib/sky/sky.worker.ts",import.meta.url),{type:"module"}));
  client.current=runner;runner.request(current.current);return()=>{runner.dispose();if(client.current===runner)client.current=null;};
 },[catalog,computeAttempt]);
 useEffect(()=>{client.current?.request(context)},[context]);
 useEffect(()=>{if(mode!=="live")return;const tick=()=>{if(!client.current?.busy)setContext(c=>({...c,instantUtc:new Date().toISOString()}))};tick();const timer=setInterval(tick,1000);return()=>clearInterval(timer)},[mode]);
 useEffect(()=>{let alive=true,permission:PermissionStatus|undefined;
  const changed=()=>{if(!alive||!permission)return;if(permission.state==="granted"&&!geoPending.current)requestLocation();else if(permission.state==="denied"){geoGeneration.current++;geoPending.current=false;clearTimeout(geoTimer.current);setGeoState("denied")}};
  navigator.permissions?.query({name:"geolocation"}).then(value=>{if(!alive)return;permission=value;permission.addEventListener("change",changed);changed();}).catch(()=>{});
  return()=>{alive=false;permission?.removeEventListener("change",changed);geoGeneration.current++;geoPending.current=false;clearTimeout(geoTimer.current)};
 },[]);
 useEffect(()=>{const controller=new AbortController();setZoneState("loading");
  fetch("/api/location/time-zone",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({latitude:context.latitude,longitude:context.longitude}),cache:"no-store",signal:AbortSignal.any([controller.signal,AbortSignal.timeout(10000)])}).then(r=>{if(!r.ok)throw new Error();return r.json()}).then(data=>{if(!Array.isArray(data.zones)||!data.zones.length||!data.zones.every((z:string)=>typeof z==="string"&&validZone(z)))throw new Error();setZones(data.zones);setAutoZone(data.zones[0]);setZoneState("ready")}).catch(()=>{if(!controller.signal.aborted)setZoneState("error")});return()=>controller.abort();
 },[context.latitude,context.longitude]);
 useEffect(()=>{if(context.source==="example"||context.placeName)return;const controller=new AbortController(),latitude=context.latitude,longitude=context.longitude;
  fetch("/api/location/places",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({latitude,longitude}),cache:"no-store",signal:AbortSignal.any([controller.signal,AbortSignal.timeout(10000)])}).then(r=>{if(!r.ok)throw new Error();return r.json()}).then(data=>{if(!controller.signal.aborted)setPlaceHint(data.places[0]?{latitude,longitude,place:data.places[0]}:null)}).catch(()=>{});return()=>controller.abort();
 },[context.latitude,context.longitude,context.source,context.placeName]);
 useEffect(()=>{if(modal){setFormError(false);if(!dialog.current?.open)dialog.current?.showModal();const id=requestAnimationFrame(()=>document.getElementById('dialog-title')?.focus({preventScroll:true}));return()=>cancelAnimationFrame(id)}else if(dialog.current?.open)dialog.current.close()},[modal]);
 useEffect(()=>{const changed=()=>setFullScreen(Boolean(document.fullscreenElement));const key=(e:KeyboardEvent)=>{if(e.key==="Escape")setLayerMenu(false)};document.addEventListener("fullscreenchange",changed);document.addEventListener("keydown",key);return()=>{document.removeEventListener("fullscreenchange",changed);document.removeEventListener("keydown",key)}},[]);
 function cancelLocationRequest(){geoGeneration.current++;geoPending.current=false;clearTimeout(geoTimer.current);if(geoState==="loading")setGeoState("idle")}
 function requestLocation(){
  if(!navigator.geolocation){setGeoState("unsupported");return;}
  const generation=++geoGeneration.current;geoPending.current=true;setGeoState("loading");clearTimeout(geoTimer.current);
  geoTimer.current=setTimeout(()=>{if(generation===geoGeneration.current){geoGeneration.current++;geoPending.current=false;setGeoState("timeout")}},12000);
  navigator.geolocation.getCurrentPosition(position=>{if(generation!==geoGeneration.current)return;geoPending.current=false;clearTimeout(geoTimer.current);try{const next=positionContext(position,current.current);setContext(next);setDraftLat(String(next.latitude));setDraftLon(String(next.longitude));setZoneOverride(null);setGeoState("ready")}catch{setGeoState("unavailable")}},error=>{if(generation!==geoGeneration.current)return;geoPending.current=false;clearTimeout(geoTimer.current);setGeoState(error.code===1?"denied":error.code===3?"timeout":"unavailable")},{enableHighAccuracy:true,maximumAge:0,timeout:10000});
 }
 const objects=useMemo<SelectedObject[]>(()=>catalog?[
  ...catalog.stars.map((s,index)=>({id:s.id,name:s.name,kind:"star" as const,index})),
  ...SOLAR_IDS.map((id,i)=>({id,name:messages[language].celestialNames[id],kind:"solar" as const,index:catalog.stars.length+i})),
  ...catalog.constellations.map((c,i)=>({id:c.id,name:c.names[language],kind:"constellation" as const,index:catalog.stars.length+9+i})),
  ...(catalog.deepSky??[]).map((d,i)=>({id:d.id,name:d.name,kind:"deepSky" as const,index:catalog.stars.length+9+catalog.constellations.length+i}))
 ]:[],[catalog,language]);
 const searchable=useMemo(()=>objects.map(object=>{
  let aliases="";if(catalog&&object.kind==="star"){const s=catalog.stars[object.index];aliases=`${s.designation} HIP ${s.hip??""}`}
  if(catalog&&object.kind==="constellation"){const c=catalog.constellations.find(c=>c.id===object.id)!;aliases=`${c.iau} ${c.names.tr} ${c.names.en}`}
  if(catalog&&object.kind==="deepSky"){const d=catalog.deepSky!.find(d=>d.id===object.id)!;aliases=`${d.designation} ${d.aliases.join(" ")}`}
  if(object.kind==="solar")aliases=`${messages.tr.celestialNames[object.id as keyof typeof messages.tr.celestialNames]} ${messages.en.celestialNames[object.id as keyof typeof messages.en.celestialNames]}`;
  return {object,key:normalize(`${object.name} ${object.id} ${aliases}`)};
 }),[objects,catalog]);
 const found=query.trim()?searchable.filter(row=>row.key.includes(normalize(query.trim()))).slice(0,12).map(row=>row.object):[];
 const chosen=objects.find(o=>o.id===selected),shown=frame?.context??context;
 const format=(n:number,digits=1)=>Number.isFinite(n)?new Intl.NumberFormat(language,{maximumFractionDigits:digits,minimumFractionDigits:digits}).format(n):"—";
 function select(id:string,focus=false){setSelected(id);setCardExpanded(true);setQuery("");setLayerMenu(false);
  if(focus&&catalog){const index=objectIndex(catalog,id);if(frame&&index>=0&&frame.canPublishAzimuth&&frame.context.latitude===context.latitude&&frame.context.longitude===context.longitude&&frame.context.instantUtc===context.instantUtc)setCamera(c=>normalizedCamera({...c,azimuth:frame.angles[index*2],altitude:frame.angles[index*2+1]}));else focusPending.current=id;}
  requestAnimationFrame(()=>document.getElementById("object-heading")?.focus({preventScroll:true}));
 }
 function openAccount(view:'login'|'register'){setAccountEntry(e=>({view,sequence:e.sequence+1}));openNotebook()}
 function openNotebook(){setNotebookSection("all");setNotebookVisited(true);setModal("notebook")}
 function openSavedPlaces(){setNotebookSection("places");setNotebookVisited(true);setModal("notebook")}
 function useSavedLocation(location:NotebookLocation){cancelLocationRequest();const next=observerAtSavedLocation(location,current.current);validateContext(next);setContext(next);setZoneOverride(null);setModal(null)}
 function openLocation(){setDraftName(context.placeName??"");setDraftElevation(context.elevationMeters===null?"":String(context.elevationMeters));setDraftLat(String(context.latitude));setDraftLon(String(context.longitude));setShowEarth(false);setModal("location")}
 function openTime(){cancelLocationRequest();const draft=timeDraft(context.instantUtc,zone,Boolean(zoneOverride)||(zoneState==="ready"&&zones.length===1));setDraftTime(draft.value);setTimeBasis(draft.basis);setOccurrence("reject");setModal("time")}
 function navigateTo(id:string,instant:string){cancelLocationRequest();const next={...current.current,instantUtc:instant};validateContext(next);setMode("simulation");setContext(next);focusPending.current=id;setSelected(id);setCardExpanded(true);setQuery("");setModal(null);}
 function openTerm(id=""){setTermQuery(id);setModal("glossary")}
 function switchLanguage(next:Language){setLanguage(next);history.replaceState(null,"",`/${next}`)}
 async function toggleScreen(){setScreenError(false);try{if(document.fullscreenElement)await document.exitFullscreen();else await shell.current?.requestFullscreen()}catch{setScreenError(true)}}
 const layerRows:[keyof Layers,string][]=[["constellations",t.constellationLines],["art",t.art],["atmosphere",t.atmosphere],["landscape",t.landscape],["azimuthalGrid",t.azimuthalGrid],["equatorialGrid",t.equatorialGrid],["deepSky",t.deepSkyLayer],["night",t.night]];
 const zoneOptions=[...new Set(["UTC",...zones,zone,...(typeof Intl.supportedValuesOf==="function"?Intl.supportedValuesOf("timeZone"):[])])].sort();
 const date=frame?new Date(frame.context.instantUtc):null;
 const geoMessage=geoState==="denied"?t.gpsDenied:geoState==="timeout"?t.gpsTimeout:geoState==="unsupported"?t.gpsUnsupported:geoState==="unavailable"?t.gpsUnavailable:null;
 const locationLabel=shown.placeName||(shown.source==="example"?t.sample:placeHint&&placeHint.latitude===shown.latitude&&placeHint.longitude===shown.longitude?(language==="tr"?`${placeTitle(placeHint.place)} ${p.near}`:`${p.near} ${placeTitle(placeHint.place)}`):shown.source==="device"?t.deviceLocation:t.manual);
 const dialogTitle=modal==="menu"?t.menu:modal==="offline"?(language==="tr"?"Uygulama ve çevrimdışı":"App and offline"):modal==="location"?t.location:modal==="time"?t.time:modal==="glossary"?t.terms:modal==="compass"?compassText[language].title:modal==="tonight"?p.tonight:modal==="calendar"?p.calendar:modal==="notebook"?t.notebook:t.sources;
 return <div ref={shell} className={`app-shell${layers.night?" night":""}`} data-language={language} data-mode={mode} data-selected={selected??""} data-frame-sequence={frame?.sequence??0} data-menu-open={modal==="menu"} data-load-state={loadState} data-first-frame-ms={firstFrameMs}>
  <a className="skip-link" href="#sky-search">{t.search}</a>
  <main className="map-pane" aria-label={t.sky}>
   <h1 className="sr-only">{t.sky}</h1>
   {catalog&&<SkyMap catalog={catalog} frame={frame} camera={camera} onCamera={setCamera} language={language} text={messages[language]} selected={selected} layers={layers} onSelect={id=>select(id)}/>}
   <div className="floating-brand"><button className="icon-button glass menu-button" aria-label={t.openMenu} onClick={()=>setModal("menu")}><Icon name="menu"/></button><span>yorungez<span>.</span></span></div>
   <div className="search-wrap glass"><Icon name="search"/><input id="sky-search" ref={search} value={query} placeholder={t.searchHelp} aria-label={t.search} autoComplete="off" onChange={e=>setQuery(e.target.value)} onKeyDown={e=>{if(e.key==="Escape")setQuery("");if(e.key==="Enter"&&found[0]){e.preventDefault();select(found[0].id,true)}}}/>{query&&<button className="icon-button" aria-label={t.clear} onClick={()=>setQuery("")}>×</button>}
    {query&&<div id="search-results" className="search-results glass">{found.length?found.map(object=><button key={object.id} onClick={()=>select(object.id,true)}><span>{object.kind==="deepSky"?"◎":object.kind==="constellation"?"⌁":"✧"}</span><span>{object.name}<small>{t[objectCategory(object.kind,object.id)]} · {object.id}</small></span><Icon name="arrow" size={15}/></button>):<p>{t.noResults}</p>}</div>}
   </div>
   {(!frame||loadState==="error")&&<div className="map-status glass" role="status">{loadState!=="error"&&<span className="orbit-spinner"/>}<span>{loadState==="error"?(fetchError?t.fetchError:t.computeError):loadState==="catalog"?t.catalogLoading:t.calculationLoading}</span>{loadState==="error"&&<button className="primary-button" onClick={()=>catalog?setComputeAttempt(a=>a+1):setFetchAttempt(a=>a+1)}>{t.retry}</button>}</div>}
   {frame&&!frame.canPublishAzimuth&&<p className="polar-notice glass" role="status">{t.polar}</p>}
   {frame&&loadState!=="ready"&&loadState!=="error"&&(frame.context.latitude!==context.latitude||frame.context.longitude!==context.longitude||(mode==="simulation"&&frame.context.instantUtc!==context.instantUtc))&&<p className="updating glass" role="status">{t.updating}</p>}
   <div className="map-tools"><button className="tool-single glass" aria-label={p.wide} title={p.wide} onClick={()=>setCamera(c=>({...c,altitude:90,fieldOfView:240}))}>◎</button><div className="tool-stack glass"><button aria-label={t.zoomIn} onClick={()=>setCamera(c=>normalizedCamera({...c,fieldOfView:c.fieldOfView/1.3}))}><Icon name="plus"/></button><button aria-label={t.zoomOut} onClick={()=>setCamera(c=>normalizedCamera({...c,fieldOfView:c.fieldOfView*1.3}))}><Icon name="minus"/></button></div><button className="tool-single glass" aria-label={t.resetCamera} onClick={()=>setCamera(initialCamera)}><Icon name="compass"/></button><button className="tool-single glass" aria-label={fullScreen?t.exitFullScreen:t.fullScreen} aria-pressed={fullScreen} onClick={toggleScreen}><Icon name="expand"/></button></div>
   <div className="bottom-context"><button className="location-chip glass" onClick={openLocation}><Icon name="location"/><span>{locationLabel}<small>{format(shown.latitude,6)}°, {format(shown.longitude,6)}°{shown.accuracyMeters!==undefined?` · ±${format(shown.accuracyMeters,0)} m`:""}</small></span></button>
    <div className="time-bar glass"><button className={`time-mode ${mode}`} onClick={()=>mode==="live"?openTime():setMode("live")}><span className="live-dot"/>{mode==="live"?t.live:t.simulation}</button><button className="time-display" onClick={openTime}><strong>{date?new Intl.DateTimeFormat(language,{timeZone:zone,dateStyle:"medium",timeStyle:"medium"}).format(date):"—"}</strong><span>{zone} · {date?new Intl.DateTimeFormat("en",{timeZone:zone,timeZoneName:"longOffset"}).formatToParts(date).find(p=>p.type==="timeZoneName")?.value:""}</span><small>{date?new Intl.DateTimeFormat(language,{timeZone:"UTC",dateStyle:"medium",timeStyle:"medium"}).format(date):"—"} UTC</small></button>{mode==="simulation"&&<button className="now-button" aria-label={t.now} title={t.now} onClick={()=>setMode("live")}><Icon name="arrow"/></button>}</div>
   </div>
   <div className="layer-dock"><button className="glass layer-launch" onClick={()=>setLayerMenu(!layerMenu)} aria-label={t.allLayers} aria-expanded={layerMenu} aria-controls="layer-panel"><Icon name="layers"/><span>{t.layers}</span><span className="layer-count">{Object.values(layers).filter(Boolean).length}</span></button>
    {layerMenu&&<section id="layer-panel" className="layer-panel glass" aria-label={t.allLayers}><div className="popover-heading"><h2>{t.allLayers}</h2><button className="icon-button" aria-label={t.close} onClick={()=>setLayerMenu(false)}>×</button></div>{layerRows.map(([key,label])=><label key={key} className="layer-row"><span>{label}</span><input type="checkbox" checked={layers[key]} onChange={e=>setLayers(s=>({...s,[key]:e.target.checked}))}/></label>)}<button className="layer-row screen-row" aria-pressed={fullScreen} onClick={toggleScreen}><span>{fullScreen?t.exitFullScreen:t.fullScreen}</span><Icon name="expand"/></button><p className="muted compact">{t.layerHelp}</p></section>}
   </div>
   <div className="map-caption"><span>{layers.landscape?t.scene:""}</span><span>{t.view} {format(camera.azimuth,0)}° · {t.altitude} {format(camera.altitude,0)}° · {format(camera.fieldOfView,1)}°</span></div>
   {screenError&&<p className="screen-error glass" role="status">{t.fullScreenError}</p>}
   <p id="map-help" className="sr-only">{t.mapHelp}</p>
  </main>
  {catalog&&chosen&&<ObjectCard key={chosen.id+":"+language} object={chosen} catalog={catalog} frame={frame} language={language} onClose={()=>{setSelected(null);document.querySelector<HTMLElement>(".sky-viewport")?.focus()}} compact={!cardExpanded} onExpand={()=>setCardExpanded(true)} onFocus={()=>{select(chosen.id,true);if(matchMedia("(max-width:650px)").matches)setCardExpanded(false)}} onCompass={()=>setModal("compass")} onNotebook={openNotebook} onTerm={openTerm}/>}
  {(pwa.offline||pwa.waiting)&&<button type="button" className="pwa-badge glass" onClick={()=>setModal("offline")}>{pwa.offline?(language==="tr"?"Çevrimdışı · genel gökyüzü":"Offline · public sky"):(language==="tr"?"Güncelleme hazır":"Update ready")}</button>}
  <dialog ref={dialog} className={`app-dialog glass ${modal==="menu"?"drawer-dialog":modal==="tonight"||modal==="calendar"?"drawer-dialog planning-dialog":modal==="glossary"?"glossary-dialog":""}`} onClose={()=>setModal(null)} aria-labelledby="dialog-title">
   <div className="dialog-top">{modal!=="menu"&&<button type="button" className="icon-button panel-back" aria-label={language==="tr"?"Menüye geri dön":"Back to menu"} title={language==="tr"?"Menüye geri dön":"Back to menu"} onClick={()=>setModal("menu")}>←</button>}<h2 id="dialog-title" tabIndex={-1}>{dialogTitle}</h2><button className="icon-button" aria-label={modal==="menu"?t.closeMenu:t.close} onClick={()=>setModal(null)}>×</button></div>
   {modal==="menu"&&<><div className="drawer-brand">yorungez<span>.</span></div><section className="drawer-account" aria-label={language==='tr'?'Hesap':'Account'}><AccountStatus session={account} language={language}/>{account.status==='signed-in'&&account.user?<><strong>{accountName(account.user)||(language==='tr'?'Hesabım':'My account')}</strong><small>{account.user.email}</small><div className="notebook-actions"><button type="button" className="inline-term" onClick={openNotebook}>{language==='tr'?'Hesabım ve defterim':'My account and notebook'}</button><button type="button" className="inline-term" disabled={account.busy} onClick={()=>void account.logout()}>{language==='tr'?'Çıkış yap':'Sign out'}</button></div></>:<div className="account-tabs"><button type="button" className="secondary-button" onClick={()=>openAccount('login')}>{language==='tr'?'Giriş yap':'Sign in'}</button><button type="button" className="primary-button" onClick={()=>openAccount('register')}>{language==='tr'?'Kayıt ol':'Create account'}</button></div>}</section><nav className="drawer-nav" aria-label={t.menu}><button onClick={()=>setModal(null)} aria-current="page"><Icon name="compass"/>{t.sky}</button><button onClick={()=>setModal("tonight")}><Icon name="moon"/>{p.tonight}</button><button onClick={()=>setModal("calendar")}><Icon name="clock"/>{p.calendar}</button><button onClick={openNotebook}><Icon name="book"/>{t.notebook}</button></nav><div className="drawer-section"><h3>{t.settings}</h3><div className="language-select"><SelectField label={language==="tr"?"Dil":"Language"} language={language} value={language} onChange={v=>switchLanguage(v as Language)} options={[{value:"tr",label:"Türkçe"},{value:"en",label:"English"}]}/></div><button className="menu-action" onClick={()=>{setModal(null);setLayerMenu(true)}}>{t.layers}<Icon name="layers"/></button><button className="menu-action" onClick={openLocation}>{t.location}<Icon name="location"/></button><button className="menu-action" onClick={openTime}>{t.time}<Icon name="clock"/></button><button className="menu-action" onClick={()=>setModal("compass")}>{compassText[language].title}<Icon name="compass"/></button></div><div className="drawer-section"><button className="menu-action" onClick={()=>setModal("offline")}>{language==="tr"?"Uygulama ve çevrimdışı":"App and offline"}<Icon name="info"/></button><button className="menu-action" onClick={()=>openTerm()}>{t.terms}<Icon name="book"/></button><button className="menu-action" onClick={()=>setModal("sources")}>{t.sourceAttribution}<Icon name="info"/></button></div><p className="muted compact">{t.sceneHelp}</p></>}
   {notebookVisited&&<div hidden={modal!=="notebook"}><AccountNotebook session={account} entry={accountEntry} onTerm={openTerm} focusSection={notebookSection} onUseLocation={useSavedLocation} visible={modal==="notebook"} language={language} context={context} target={chosen?{id:chosen.id,name:chosen.name}:undefined} resolveTarget={id=>objects.find(o=>o.id===id)?.name} onSelect={id=>{setModal(null);select(id,true)}}/></div>}
   {modal==="offline"&&<PwaPanel language={language} pwa={pwa}/>}
   {modal==="tonight"&&(zoneState==="loading"&&!zoneOverride?<p role="status">{t.zoneLoading}</p>:<TonightPanel language={language} context={context} zone={zone} locationLabel={locationLabel} onNavigate={navigateTo} onTerm={openTerm} onCompass={()=>setModal("compass")}/>)}
   {modal==="calendar"&&(zoneState==="loading"&&!zoneOverride?<p role="status">{t.zoneLoading}</p>:<CalendarPanel language={language} zone={zone} instant={context.instantUtc} onNavigate={navigateTo} onTerm={openTerm}/>)}
   {modal==="compass"&&<CompassPanel language={language} target={chosen&&frame?.canPublishAzimuth&&catalog?{id:chosen.id,name:chosen.name,azimuth:frame.angles[chosen.index*2],altitude:frame.angles[chosen.index*2+1],sunAltitude:frame.angles[catalog.stars.length*2+1],instantUtc:frame.context.instantUtc,latitude:frame.context.latitude}:undefined} zone={zone} simulation={mode==="simulation"} onTonight={()=>setModal("tonight")} onPolaris={context.latitude>0&&objects.some(o=>o.name==="Polaris")?()=>{const north=objects.find(o=>o.name==="Polaris")!;setModal(null);select(north.id,true)}:undefined} azimuth={camera.azimuth} onTerm={openTerm} onApply={azimuth=>{setCamera(c=>normalizedCamera({...c,azimuth}));setModal(null)}}/>}
   {modal==="location"&&<><button type="button" className="secondary-button" onClick={openSavedPlaces}>{language==="tr"?"Kayıtlı konumlarım":"My saved locations"}</button><PlaceSearch language={language} onPick={place=>{cancelLocationRequest();setDraftLat(String(place.latitude));setDraftLon(String(place.longitude));setDraftName(placeTitle(place).slice(0,80));setDraftElevation("")}}/><p className="muted">{t.gpsHelp}</p><button className="primary-button" disabled={geoState==="loading"} onClick={requestLocation}><Icon name="location"/>{geoState==="loading"?t.locating:context.source==="device"?t.refreshDevice:t.useDevice}</button>{geoMessage&&<p className="form-error" role="status">{geoMessage}</p>}{context.accuracyMeters!==undefined&&<p className="muted"><button className="inline-term" onClick={()=>openTerm("location-accuracy")}>{t.accuracy} ⓘ</button>: ±{format(context.accuracyMeters,1)} m<br/>{t.measured}: {new Intl.DateTimeFormat(language,{timeZone:zone,dateStyle:"medium",timeStyle:"medium"}).format(new Date(context.measuredAtUtc!))}</p>}
    <form onSubmit={event=>{event.preventDefault();const data=new FormData(event.currentTarget);try{const next:ObserverContext={...current.current,latitude:parseCoordinate(String(data.get("latitude"))),longitude:parseCoordinate(String(data.get("longitude"))),elevationMeters:draftElevation.trim()?parseCoordinate(String(data.get("elevation"))):null,placeName:String(data.get("placeName")??"").trim()||undefined,accuracyMeters:undefined,measuredAtUtc:undefined,source:"manual"};validateContext(next);if(next.latitude===current.current.latitude&&next.longitude===current.current.longitude&&current.current.source==="device"){next.source="device";next.accuracyMeters=current.current.accuracyMeters;next.measuredAtUtc=current.current.measuredAtUtc;}geoGeneration.current++;geoPending.current=false;clearTimeout(geoTimer.current);setGeoState("idle");setContext(next);setZoneOverride(null);setModal(null)}catch{setFormError(true)}}}><p className="muted compact">{t.coordinateHelp}</p><label>{p.placeName}<input name="placeName" value={draftName} onChange={e=>{cancelLocationRequest();setDraftName(e.target.value)}} maxLength={80}/></label><div className="form-grid"><label>{t.latitude}<input name="latitude" value={draftLat} onChange={e=>{cancelLocationRequest();setDraftLat(e.target.value)}} inputMode="decimal" required/></label><label>{t.longitude}<input name="longitude" value={draftLon} onChange={e=>{cancelLocationRequest();setDraftLon(e.target.value)}} inputMode="decimal" required/></label></div><label className="elevation-input">{p.elevation}<input name="elevation" value={draftElevation} onChange={e=>{cancelLocationRequest();setDraftElevation(e.target.value)}} inputMode="decimal"/></label><p className="muted compact">{p.elevationHelp}</p>{formError&&<p className="form-error" role="alert">{t.contextError}</p>}<p className="muted compact">{t.locationPrivate}</p><button className="secondary-button" type="button" onClick={()=>{cancelLocationRequest();setShowEarth(true)}}>{t.mapConsent} ↗</button><p className="muted compact">{t.mapPrivacy}</p>{showEarth&&<><EarthPicker latitude={context.latitude} longitude={context.longitude} language={language} onPick={(lat,lon)=>{cancelLocationRequest();setDraftLat(String(lat));setDraftLon(String(lon))}}/><p className="muted compact">{t.earthMapHelp}</p></>}<div className="form-actions"><button className="secondary-button" type="button" onClick={()=>setModal(null)}>{t.cancel}</button><button className="primary-button">{t.apply}</button></div></form></>}
   {modal==="time"&&<form onSubmit={event=>{event.preventDefault();try{if(timeBasis==="local"&&!zoneOverride&&(zones.length>1||zoneState!=="ready"))throw new Error();const value=String(new FormData(event.currentTarget).get("instant")??"");const next={...current.current,instantUtc:localToUtc(value,timeBasis==="UTC"?"UTC":zone,occurrence)};validateContext(next);setMode("simulation");setContext(next);setModal(null)}catch{setFormError(true)}}}><p className="muted">{t.zoneHelp}</p><SelectField label={t.timeZone} language={language} value={zoneOverride??""} searchable onChange={value=>{setZoneOverride(value||null);if(timeBasis==="local")setDraftTime(localInput(context.instantUtc,value||autoZone))}} options={[{value:"",label:`${t.autoZone} · ${autoZone}`},...zoneOptions.map(z=>({value:z,label:z}))]}/>{zoneState==="loading"&&<p className="muted" role="status">{t.zoneLoading}</p>}{zoneState==="error"&&<p className="form-error" role="status">{t.zoneFailure}</p>}{zones.length>1&&!zoneOverride&&<p className="form-error">{t.multipleZones}</p>}<div className="basis-switch"><label><input type="radio" name="basis" disabled={!zoneOverride&&(zoneState!=="ready"||zones.length>1)} checked={timeBasis==="local"} onChange={()=>{setTimeBasis("local");setDraftTime(localInput(context.instantUtc,zone))}}/>{t.localBasis}</label><label><input type="radio" name="basis" checked={timeBasis==="UTC"} onChange={()=>{setTimeBasis("UTC");setDraftTime(localInput(context.instantUtc,"UTC"))}}/>UTC</label></div><DateTimeField key={timeBasis+":"+(timeBasis==="local"?zone:"UTC")+":"+draftTime} label={timeBasis==="UTC"?t.utcTime:`${t.localTime} · ${zone}`} name="instant" defaultValue={draftTime} language={language} onChange={()=>setFormError(false)}/>{timeBasis==="local"&&<SelectField label={t.occurrence} language={language} value={occurrence} onChange={v=>setOccurrence(v as typeof occurrence)} options={[{value:"reject",label:t.rejectAmbiguous},{value:"earlier",label:t.earlier},{value:"later",label:t.later}]}/>}{formError&&<p className="form-error" role="alert">{t.timeError}</p>}<div className="form-actions"><button type="button" className="secondary-button" onClick={()=>setModal(null)}>{t.cancel}</button><button className="primary-button">{t.apply}</button></div></form>}
   {modal==="glossary"&&<><p className="muted">{t.termsHelp}</p><input className="term-search" value={termQuery} onChange={e=>setTermQuery(e.target.value)} placeholder={t.termSearch} aria-label={t.termSearch}/><div className="term-list">{terms.filter(term=>!termQuery||normalize(`${term.id} ${term.translations[language].name} ${term.abbreviation??""} ${term.translations[language].aliases.join(" ")}`).includes(normalize(termQuery))).map(term=><article key={term.id}><h3>{term.translations[language].name}{term.abbreviation&&<small>{term.abbreviation}</small>}</h3><p>{term.translations[language].definition}</p><a href={term.sources[0]} target="_blank" rel="noreferrer">{t.source} ↗</a></article>)}</div></>}
   {modal==="sources"&&<div className="sources-content"><p>{t.sourcesHelp}</p><a href="https://github.com/astronexus/HYG-Database" target="_blank" rel="noreferrer">HYG · CC BY-SA 4.0 ↗</a><a href="https://github.com/ofrohn/d3-celestial" target="_blank" rel="noreferrer">d3-celestial · BSD-3-Clause ↗</a><p>{t.deepSkyHelp}</p><a href="https://github.com/mattiaverga/OpenNGC" target="_blank" rel="noreferrer">OpenNGC · CC BY-SA 4.0 ↗</a><p>{t.artCredit}</p><a href="https://github.com/Stellarium/stellarium-skycultures/tree/014fbb5e59233d133c22f9811af96b67d05a95c9/western" target="_blank" rel="noreferrer">Stellarium · Johan Meuris ↗</a><a href="https://artlibre.org/licence/lal/en/" target="_blank" rel="noreferrer">Free Art License ↗</a><p>{t.sceneHelp}</p><p>Stara Lesna Meadows · Ľubomír Hambálek</p><a href="https://stellarium.org/landscapes-europe.html" target="_blank" rel="noreferrer">{language==="tr"?"Panorama kaynağı":"Panorama source"} ↗</a><a href="https://creativecommons.org/licenses/by-sa/4.0/" target="_blank" rel="noreferrer">CC BY-SA 4.0 ↗</a><p>{t.calculationHelp}</p><p>{t.scopeHelp}</p><a href="https://github.com/cosinekitty/astronomy/tree/v2.1.19" target="_blank" rel="noreferrer">Astronomy Engine ↗</a></div>}
  </dialog>
 </div>;
}
