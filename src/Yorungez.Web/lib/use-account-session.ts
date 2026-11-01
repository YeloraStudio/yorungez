"use client";
import {useCallback,useEffect,useRef,useState} from 'react';
import {accountRequest,AccountError,type AccountUser} from './account.ts';
import type {Language} from './sky/types.ts';
export type AccountStatus='checking'|'signed-in'|'signed-out'|'unavailable'|'offline';
export function useAccountSession(language:Language,visible:boolean){
 const [user,setUser]=useState<AccountUser|null>(null),[status,setStatus]=useState<AccountStatus>('checking'),[busy,setBusy]=useState(false),generation=useRef(0);
 const check=useCallback(async()=>{const seq=++generation.current;if(!navigator.onLine){setStatus('offline');return}setStatus('checking');
  try{const next=await accountRequest('/api/account/me',language);if(seq===generation.current){setUser(next);setStatus('signed-in')}}
  catch(e){if(seq===generation.current){if(e instanceof AccountError&&e.status===401){setUser(null);setStatus('signed-out')}else setStatus(navigator.onLine?'unavailable':'offline')}}
 },[language]);
 useEffect(()=>{if(visible)void check()},[visible,check]);
 useEffect(()=>{const refresh=()=>{if(visible)void check()},offline=()=>{generation.current++;setStatus('offline')};window.addEventListener('focus',refresh);window.addEventListener('online',refresh);window.addEventListener('offline',offline);
  const channel=typeof BroadcastChannel==='undefined'?null:new BroadcastChannel('yorungez-account');if(channel)channel.onmessage=()=>void check();
  return()=>{generation.current++;window.removeEventListener('focus',refresh);window.removeEventListener('online',refresh);window.removeEventListener('offline',offline);channel?.close()};
 },[visible,check]);
 function announce(){if(typeof BroadcastChannel!=='undefined'){const c=new BroadcastChannel('yorungez-account');c.postMessage('changed');c.close()}}
 function signedIn(next:AccountUser){generation.current++;setUser(next);setStatus('signed-in');announce()}
 function sessionLost(){generation.current++;setUser(null);setStatus('signed-out')}
 async function logout(){setBusy(true);try{await accountRequest('/api/account/logout',language,{});sessionLost();announce()}catch{setStatus(navigator.onLine?'unavailable':'offline')}finally{setBusy(false)}}
 return {user,status,busy,check,signedIn,sessionLost,logout};
}
export type AccountSession=ReturnType<typeof useAccountSession>;
