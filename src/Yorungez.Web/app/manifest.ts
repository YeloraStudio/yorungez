import type {MetadataRoute} from 'next';
import {brand} from '../lib/brand';
export default function manifest():MetadataRoute.Manifest{return {id:'/',name:'yorungez',short_name:'yorungez',description:'Explore the sky by place and time.',lang:'en',start_url:'/en',scope:'/',display:'standalone',background_color:'#3C3F43',theme_color:'#3C3F43',icons:[{src:brand.app192.src,sizes:'192x192',type:'image/png',purpose:'any'},{src:brand.app512.src,sizes:'512x512',type:'image/png',purpose:'any'},{src:brand.maskable512.src,sizes:'512x512',type:'image/png',purpose:'maskable'}]}}
