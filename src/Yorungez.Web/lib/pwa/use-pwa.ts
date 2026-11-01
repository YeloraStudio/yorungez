"use client";
import {useCallback,useEffect,useRef,useState} from 'react';
export interface PublicPack {version:string;coreReady:boolean;optionalReady:boolean;optionalCount:number;optionalTotal:number;coreBytes:number;optionalBytes:number;unavailable:boolean}
export function usePwa(enabled:boolean){
 const [state,setState]=useState<'starting'|'ready'|'error'|'unsupported'|'development'>('starting'),[pack,setPack]=useState<PublicPack|null>(null),[offline,setOffline]=useState(false),[waiting,setWaiting]=useState(false),[busy,setBusy]=useState(false),[error,setError]=useState(false),[blocked,setBlocked]=useState(false);
 const registration=useRef<ServiceWorkerRegistration|null>(null),reloadRequested=useRef(false),[attempt,setAttempt]=useState(0);
 const send=useCallback((type:string)=>registration.current?.active?.postMessage({type}),[]);
 useEffect(()=>{
  const updateOnline=()=>{setOffline(!navigator.onLine);if(navigator.onLine)send('CHECK_NETWORK')};updateOnline();window.addEventListener('online',updateOnline);window.addEventListener('offline',updateOnline);
  return()=>{window.removeEventListener('online',updateOnline);window.removeEventListener('offline',updateOnline)};
 },[send]);
 useEffect(()=>{
  if(!enabled)return;
  if(process.env.NODE_ENV!=='production'){setState('development');return}
  if(!('serviceWorker' in navigator)||!window.isSecureContext){setState('unsupported');return}
  let alive=true;const cleanups:(()=>void)[]=[];
  const message=(e:MessageEvent)=>{if(!alive)return;const data=e.data;
   if(data?.type==='PACK_STATUS'){setPack(data);setOffline(!navigator.onLine||data.unavailable);setState(data.coreReady?'ready':'error');setBusy(false);setWaiting(registration.current?.waiting?.state==='installed')}
   if(data?.type==='NETWORK_STATE')setOffline(!navigator.onLine||data.unavailable);
   if(data?.type==='PACK_ERROR'){setError(true);setBusy(false)}
   if(data?.type==='UPDATE_BLOCKED'){setBlocked(true);reloadRequested.current=false}
  };
  const changed=()=>{setWaiting(registration.current?.waiting?.state==='installed');if(reloadRequested.current){window.location.reload();return}send('STATUS');send('CHECK_NETWORK')};
  const resumed=()=>{if(!document.hidden)send('CHECK_NETWORK')};
  navigator.serviceWorker.addEventListener('message',message);navigator.serviceWorker.addEventListener('controllerchange',changed);
  document.addEventListener('visibilitychange',resumed);window.addEventListener('pageshow',resumed);
  void navigator.serviceWorker.register('/sw.js',{scope:'/',updateViaCache:'none'}).then(reg=>{
   if(!alive)return;registration.current=reg;setWaiting(!!reg.waiting);if(reg.active){reg.active.postMessage({type:'STATUS'});reg.active.postMessage({type:'CHECK_NETWORK'})}
   const found=()=>{const worker=reg.installing;if(!worker)return;const change=()=>{if(worker.state==='installed'){setWaiting(!!reg.waiting);if(!navigator.serviceWorker.controller)void navigator.serviceWorker.ready.then(()=>send('STATUS'))}if(worker.state==='redundant'&&!reg.active)setState('error')};worker.addEventListener('statechange',change);cleanups.push(()=>worker.removeEventListener('statechange',change));};reg.addEventListener('updatefound',found);cleanups.push(()=>reg.removeEventListener('updatefound',found));found();send('STATUS');
  }).catch(()=>{if(alive)setState('error')});
  return()=>{alive=false;cleanups.forEach(fn=>fn());navigator.serviceWorker.removeEventListener('message',message);navigator.serviceWorker.removeEventListener('controllerchange',changed);document.removeEventListener('visibilitychange',resumed);window.removeEventListener('pageshow',resumed)};
 },[enabled,attempt,send]);
 function images(){setBusy(true);setError(false);send('CACHE_IMAGES')}
 function refresh(){setError(false);if(registration.current?.active){send('CHECK_NETWORK');send('REPAIR_CORE');void registration.current.update().catch(()=>setError(true))}else{setState('starting');setAttempt(a=>a+1)}}
 function update(){const worker=registration.current?.waiting;if(!worker||worker.state!=='installed'){setWaiting(false);reloadRequested.current=false;return}setBlocked(false);reloadRequested.current=true;worker.postMessage({type:'ACTIVATE_UPDATE'})}
 return {state,pack,offline,waiting,busy,error,blocked,images,refresh,update};
}
export type PwaController=ReturnType<typeof usePwa>;
