import type {Language} from './sky/types.ts';
export const languageCookieName='yorungez-language';
export const supportedLanguage=(value:unknown):value is Language=>value==='en'||value==='tr';
export function languageFromCookie(cookies:string):Language|undefined{
 const value=cookies.split(';').map(v=>v.trim()).find(v=>v.startsWith(languageCookieName+'='))?.slice(languageCookieName.length+1);
 return supportedLanguage(value)?value:undefined;
}
export function languageCookie(value:Language,secure:boolean){
 return `${languageCookieName}=${value}; Path=/; Max-Age=31536000; SameSite=Lax${secure?'; Secure':''}`;
}
