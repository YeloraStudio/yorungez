"use client";
import { useEffect, useRef, useState } from "react";
import type { Language } from "../lib/sky/types.ts";
export default function EarthPicker({latitude,longitude,language,onPick}:{latitude:number;longitude:number;language:Language;onPick:(lat:number,lon:number)=>void}){
  const host=useRef<HTMLDivElement>(null),callback=useRef(onPick),[failed,setFailed]=useState(false);callback.current=onPick;
  useEffect(()=>{
    let cancelled=false,map:import("leaflet").Map|undefined;
    import("leaflet").then(L=>{if(cancelled||!host.current)return;
      map=L.map(host.current,{zoomControl:false,attributionControl:false}).setView([latitude,longitude],12);
      L.control.zoom({zoomInTitle:language==="tr"?"Yakınlaştır":"Zoom in",zoomOutTitle:language==="tr"?"Uzaklaştır":"Zoom out"}).addTo(map);
      L.control.attribution({prefix:false}).addTo(map);
      L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png",{maxZoom:19,attribution:`&copy; <a href="https://www.openstreetmap.org/copyright" target="_blank" rel="noreferrer">OpenStreetMap</a> ${language==="tr"?"katkıda bulunanlar":"contributors"}`}).on("tileerror",()=>{if(!cancelled)setFailed(true)}).addTo(map);
      const marker=L.circleMarker([latitude,longitude],{radius:8,color:"#8c3549",fillColor:"#bd7081",fillOpacity:.8}).addTo(map);
      map.on("click",event=>{const lon=((event.latlng.lng+180)%360+360)%360-180;marker.setLatLng([event.latlng.lat,lon]);callback.current(event.latlng.lat,lon);});
      map.on("keypress",event=>{if(event.originalEvent.key==="Enter"&&map){const c=map.getCenter(),lon=((c.lng+180)%360+360)%360-180;marker.setLatLng([c.lat,lon]);callback.current(c.lat,lon);}});
    }).catch(()=>{if(!cancelled)setFailed(true)});
    return()=>{cancelled=true;map?.remove();};
  },[latitude,longitude]);
  return <><div ref={host} className="earth-picker" role="region" aria-label={language==="tr"?"Dünya haritasında nokta seç":"Pick a point on the Earth map"}/>{failed&&<p className="form-error" role="status">{language==="tr"?"Harita tam yüklenemedi. Manuel koordinat girişi kullanılabilir.":"The map could not load completely. Manual coordinates remain available."}</p>}</>;
}
