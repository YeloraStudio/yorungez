"use client";
import {useState} from 'react';
import {accountRequest,type AccountUser} from '../lib/account.ts';
import type {Language} from '../lib/sky/types.ts';
export default function ProfileNameForm({language,user,onSaved}:{language:Language;user:AccountUser;onSaved:(user:AccountUser)=>void}){
 const [busy,setBusy]=useState(false),[error,setError]=useState(false),tr=language==='tr';
 return <section className="account-panel"><p>{tr?'Profilini tamamlamak için adını ve soyadını ekle.':'Add your first and last name to complete your profile.'}</p>{error&&<p role="alert">{tr?'Profil kaydedilemedi. Alanları ve bağlantıyı kontrol edip tekrar dene.':'Your profile could not be saved. Check the fields and connection, then retry.'}</p>}
  <form onSubmit={async e=>{e.preventDefault();const data=new FormData(e.currentTarget);setBusy(true);setError(false);try{onSaved(await accountRequest('/api/account/profile',language,{firstName:String(data.get('firstName')).trim(),lastName:String(data.get('lastName')).trim()},user.id))}catch{setError(true)}finally{setBusy(false)}}}>
   <label>{tr?'Ad':'First name'}<input name="firstName" autoComplete="given-name" maxLength={100} required defaultValue={user.firstName??''} disabled={busy}/></label>
   <label>{tr?'Soyad':'Last name'}<input name="lastName" autoComplete="family-name" maxLength={100} required defaultValue={user.lastName??''} disabled={busy}/></label>
   <button className="primary-button" disabled={busy}>{busy?(tr?'Kaydediliyor…':'Saving…'):(tr?'Adımı kaydet':'Save my name')}</button>
  </form>
 </section>;
}
