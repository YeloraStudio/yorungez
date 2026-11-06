"use client";
import {useEffect,useState} from 'react';
import {usePathname} from 'next/navigation';
import {measurement,publicMeasurementPage,readAnalyticsChoice,type AnalyticsChoice} from '../lib/measurement';
declare global {interface Window {dataLayer?:unknown[];yorungezMeasurementStarted?:boolean}}
export default function MeasurementConsent({language}:{language:'en'|'tr'}){
 const pathname=usePathname(),tr=language==='tr';
 const [choice,setChoice]=useState<AnalyticsChoice|null>(null),[ready,setReady]=useState(false),[open,setOpen]=useState(false);
 const configured=/^G-[A-Z0-9]+$/.test(measurement.ga4);
 useEffect(()=>{setChoice(readAnalyticsChoice(document.cookie));setReady(true);const show=()=>setOpen(true);window.addEventListener('yorungez:measurement-settings',show);return()=>window.removeEventListener('yorungez:measurement-settings',show);},[]);
 useEffect(()=>{
  const page=publicMeasurementPage(pathname);
  if(!ready||choice!=='accepted'||!configured||!page||window.location.hostname!=='yorungez.com')return;
  window.dataLayer??=[];
  function gtag(..._args:unknown[]){window.dataLayer!.push(arguments);}
  if(!window.yorungezMeasurementStarted){
   window.yorungezMeasurementStarted=true;
   gtag('consent','default',{analytics_storage:'granted',ad_storage:'denied',ad_user_data:'denied',ad_personalization:'denied'});
   gtag('js',new Date());
   gtag('config',measurement.ga4,{...page,send_page_view:false,allow_google_signals:false,allow_ad_personalization_signals:false,cookie_flags:'SameSite=Lax;Secure'});
   const script=document.createElement('script');script.async=true;script.id='yorungez-ga4';script.src=`https://www.googletagmanager.com/gtag/js?id=${measurement.ga4}`;document.head.append(script);
   // This independently managed container is deliberately empty; GA4 above owns measurement.
   // Never add a second Google tag to GTM without removing the direct integration.
   if(/^GTM-[A-Z0-9]+$/.test(measurement.tagManager)){
    window.dataLayer.push({'gtm.start':Date.now(),event:'gtm.js'});
    const manager=document.createElement('script');manager.async=true;manager.id='yorungez-gtm';manager.src=`https://www.googletagmanager.com/gtm.js?id=${measurement.tagManager}`;document.head.append(manager);
   }
  }
  gtag('config',measurement.ga4,{...page,send_page_view:false});gtag('event','page_view',page);
 },[choice,configured,pathname,ready]);
 function choose(next:AnalyticsChoice){document.cookie=`yorungez-analytics=${next}; Path=/; Max-Age=15552000; SameSite=Lax${window.isSecureContext?'; Secure':''}`;setChoice(next);setOpen(false);
  if(next==='declined'){
   function revoke(..._args:unknown[]){window.dataLayer?.push(arguments);}
   revoke('consent','update',{analytics_storage:'denied',ad_storage:'denied',ad_user_data:'denied',ad_personalization:'denied'});
   // Reload drops loaded third-party code. Clear first-party analytics cookies at both scopes.
   for(const row of document.cookie.split(';')){const name=row.trim().split('=')[0];if(/^_ga(?:_|$)|^_gid$|^_gat/.test(name))for(const domain of ['',`; Domain=yorungez.com`,`; Domain=.yorungez.com`])document.cookie=`${name}=; Path=/; Max-Age=0; SameSite=Lax${domain}`;}
   if(window.yorungezMeasurementStarted)window.location.reload();
  }
 }
 if(!ready||!configured||!publicMeasurementPage(pathname)||(!open&&choice))return null;
 return <aside className="measurement-consent glass" aria-label={tr?'İsteğe bağlı ölçüm':'Optional analytics'}><strong>{tr?'Yorungez’ın gelişmesine yardımcı ol':'Help improve Yorungez'}</strong><p>{tr?'İstersen genel sayfa ziyaretlerini Google Analytics ile ölçebiliriz. Kabul etmeden ölçüm araçları yüklenmez. Hesap, not, arama, konum ve sensör verilerin gönderilmez.':'Allow optional Google Analytics to measure public page visits. Measurement tools load only if you accept. Account, notes, search, location and sensor data are excluded.'}</p><div><button type="button" className="secondary-button" onClick={()=>choose('declined')}>{tr?'Reddet':'Decline'}</button><button type="button" className="primary-button" onClick={()=>choose('accepted')}>{tr?'Kabul et':'Accept'}</button><a href={`/${language}/privacy`}>{tr?'Ayrıntılar':'Details'}</a></div></aside>;
}
