import type {Metadata} from 'next';
import {brand} from './brand';
export type SiteLanguage='en'|'tr';
export const siteUrl='https://yorungez.com';
export const repositoryUrl='https://github.com/YeloraStudio/yorungez';
export const siteDescription={
 en:'Explore a live sky map, plan tonight’s observing and learn astronomy with sourced guides. Free, ad-free and open source. Android and iOS apps coming soon.',
 tr:'Canlı gökyüzü haritasını keşfet, bu geceki gözlemini planla ve kaynaklı rehberlerle astronomiyi öğren. Ücretsiz, reklamsız ve açık kaynak. Android ve iOS yakında.'
};
export function pageMetadata(lang:SiteLanguage,path:string,title:string,description:string):Metadata{
 const url=`${siteUrl}/${lang}${path}`;
 return {title,description,alternates:{canonical:url,languages:{en:`${siteUrl}/en${path}`,tr:`${siteUrl}/tr${path}`,'x-default':`${siteUrl}/en${path}`}},
  openGraph:{type:'website',url,title,description,siteName:'Yorungez',locale:lang==='tr'?'tr_TR':'en_US',alternateLocale:[lang==='tr'?'en_US':'tr_TR'],images:[{url:`${siteUrl}/discovery/yorungez-social.png`,width:1200,height:630,alt:'Yorungez — Your sky. Your discoveries.'}]},
  twitter:{card:'summary_large_image',title,description,images:[`${siteUrl}/discovery/yorungez-social.png`]}};
}
export function jsonLd(value:unknown){return JSON.stringify(value).replace(/</g,'\\u003c');}
export function siteSchema(lang:SiteLanguage){return {'@context':'https://schema.org','@graph':[
 {'@type':'Organization','@id':`${siteUrl}/#project`,name:'Yorungez',url:siteUrl,logo:`${siteUrl}${brand.app512.src}`,sameAs:[repositoryUrl],description:'A free, ad-free, not-for-profit open-source astronomy project.'},
 {'@type':'WebSite','@id':`${siteUrl}/#website`,name:'Yorungez',url:siteUrl,inLanguage:['en','tr'],publisher:{'@id':`${siteUrl}/#project`}},
 {'@type':'WebApplication',name:'Yorungez',url:`${siteUrl}/${lang}`,applicationCategory:'EducationalApplication',operatingSystem:'Web',browserRequirements:'JavaScript and a modern browser; public offline pack available on supported browsers.',inLanguage:['en','tr'],isAccessibleForFree:true,description:siteDescription[lang]}
 ]};}
