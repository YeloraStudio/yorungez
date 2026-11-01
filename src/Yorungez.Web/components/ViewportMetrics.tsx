"use client";
import {useEffect} from 'react';

/** Layout-only metrics: never read or persist position, account or sensor data. */
export default function ViewportMetrics(){
 useEffect(()=>{
  const root=document.documentElement,visual=window.visualViewport;
  let scheduled=0;
  const update=()=>{scheduled=0;root.style.setProperty('--visible-height',`${visual?.height??window.innerHeight}px`);root.style.setProperty('--visible-top',`${visual?.offsetTop??0}px`)};
  const schedule=()=>{if(!scheduled)scheduled=requestAnimationFrame(update)};
  update();window.addEventListener('resize',schedule);visual?.addEventListener('resize',schedule);visual?.addEventListener('scroll',schedule);
  return()=>{cancelAnimationFrame(scheduled);window.removeEventListener('resize',schedule);visual?.removeEventListener('resize',schedule);visual?.removeEventListener('scroll',schedule);root.style.removeProperty('--visible-height');root.style.removeProperty('--visible-top')};
 },[]);
 return null;
}
