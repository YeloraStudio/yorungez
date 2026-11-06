// Public IDs only. No account, observer, catalogue-search or sensor values belong here.
export const measurement={ga4:'G-WFZDK36X46',tagManager:'GTM-NMRWNHQF'};
export type AnalyticsChoice='accepted'|'declined';
export function readAnalyticsChoice(cookie:string):AnalyticsChoice|null{
 const v=cookie.split(';').map(x=>x.trim()).find(x=>x.startsWith('yorungez-analytics='))?.split('=')[1];
 return v==='accepted'||v==='declined'?v:null;
}
export function publicMeasurementPage(pathname:string){
 if(!/^\/(en|tr)(?:\/(?:about|mobile|privacy|terms|library(?:\/[a-z0-9-]+)?))?$/.test(pathname))return null;
 return {page_location:`https://yorungez.com${pathname}`,page_title:pathname.endsWith('/en')||pathname.endsWith('/tr')?'Yorungez — Sky':`Yorungez — ${pathname.split('/').slice(2).join(' / ')}`,page_referrer:''};
}
