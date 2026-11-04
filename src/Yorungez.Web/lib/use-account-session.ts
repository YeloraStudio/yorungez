"use client";
import {useCallback,useEffect,useRef,useState} from 'react';
import {accountRequest,AccountError,type AccountUser} from './account.ts';
import type {Language} from './sky/types.ts';
export type AccountStatus='checking'|'signed-in'|'signed-out'|'unavailable'|'offline';
export function useAccountSession(language:Language,visible:boolean){
 const [user,setUser]=useState<AccountUser|null>(null),[status,setStatus]=useState<AccountStatus>('checking'),[busy,setBusy]=useState(false),generation=useRef(0);
 const currentLanguage=useRef(language),savingLanguage=useRef(false),refreshAfterSave=useRef(false);currentLanguage.current=language;
 const check=useCallback(async()=>{if(savingLanguage.current)return;const seq=++generation.current;if(!navigator.onLine){setStatus('offline');return}setStatus('checking');
  try{const next=await accountRequest('/api/account/me',currentLanguage.current);if(seq===generation.current){setUser(next);setStatus('signed-in')}}
  catch(e){if(seq===generation.current){if(e instanceof AccountError&&e.status===401){setUser(null);setStatus('signed-out')}else setStatus(navigator.onLine?'unavailable':'offline')}}
 },[]);
 useEffect(()=>{if(visible)void check()},[visible,check]);
 useEffect(()=>{const refresh=()=>{if(visible)void check()},offline=()=>{generation.current++;setStatus('offline')};window.addEventListener('focus',refresh);window.addEventListener('online',refresh);window.addEventListener('offline',offline);
  const channel=typeof BroadcastChannel==='undefined'?null:new BroadcastChannel('yorungez-account');if(channel)channel.onmessage=()=>{generation.current++;if(savingLanguage.current)refreshAfterSave.current=true;else void check()};
  return()=>{generation.current++;window.removeEventListener('focus',refresh);window.removeEventListener('online',refresh);window.removeEventListener('offline',offline);channel?.close()};
 },[visible,check]);
 function announce(){if(typeof BroadcastChannel!=='undefined'){const c=new BroadcastChannel('yorungez-account');c.postMessage('changed');c.close()}}
 function signedIn(next:AccountUser){generation.current++;setUser(next);setStatus('signed-in');announce()}
 function sessionLost(){generation.current++;setUser(null);setStatus('signed-out')}
 async function saveLanguage(preferredLanguage:Language){
  if(!user||status!=='signed-in'||savingLanguage.current)throw new AccountError('Common.Unavailable',503);
  const seq=++generation.current,owner=user.id;savingLanguage.current=true;
  try{const next:AccountUser=await accountRequest('/api/account/language',currentLanguage.current,{preferredLanguage},owner);
   if(seq!==generation.current||next.id!==owner)throw new AccountError('Identity.AccountChanged',409);
   setUser(next);setStatus('signed-in');announce();return next;
  }catch(error){if(error instanceof AccountError&&error.status===401)sessionLost();if(error instanceof AccountError&&error.status===409)refreshAfterSave.current=true;throw error}
  finally{savingLanguage.current=false;if(refreshAfterSave.current){refreshAfterSave.current=false;void check()}}
 }
 async function logout(){generation.current++;setBusy(true);try{await accountRequest('/api/account/logout',language,{});sessionLost();announce()}catch{setStatus(navigator.onLine?'unavailable':'offline')}finally{setBusy(false)}}
 return {user,status,busy,check,signedIn,sessionLost,logout,saveLanguage};
}
export type AccountSession=ReturnType<typeof useAccountSession>;
