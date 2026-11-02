import {plainArticleText} from './article-text.ts';
export interface ArchiveImage {url:string;sourceUrl:string;credit:string;license:string;licenseUrl:string}
interface CommonsInfo {url?:string;thumburl?:string;descriptionurl?:string;mime?:string;extmetadata?:Record<string,{value?:string}>}
/** Interpret explicit per-file rights; a missing URL is not itself a missing public-domain declaration. */
export function commonsImage(info:CommonsInfo|undefined):ArchiveImage|null{
 if(!info)return null;
 const value=(key:string)=>plainArticleText(info.extmetadata?.[key]?.value??'').replace(/&amp;/g,'&').replace(/&quot;/g,'"').replace(/&#0?39;/g,"'").replace(/&nbsp;/g,' ');
 const url=info.thumburl??info.url,sourceUrl=info.descriptionurl,credit=value('Artist'),license=value('LicenseShortName');
 if(!url||!sourceUrl||!credit||!license)return null;
 if(info.mime&&!['image/jpeg','image/png','image/webp'].includes(info.mime))return null;
 try{
  const image=new URL(url),source=new URL(sourceUrl);
  if(image.protocol!=='https:'||!['upload.wikimedia.org','thumb.wikimedia.org'].includes(image.hostname)||source.protocol!=='https:'||source.hostname!=='commons.wikimedia.org'||!source.pathname.startsWith('/wiki/File:'))return null;
  if(/\.svg(?:\/|$)/i.test(image.pathname)||/\.svg$/i.test(source.pathname))return null;
  let licenseUrl=value('LicenseUrl');
  if(!licenseUrl&&license==='Public domain'&&value('Copyrighted').toLowerCase()==='false')licenseUrl=sourceUrl+'#Licensing';
  if(licenseUrl){const link=new URL(licenseUrl);if(link.protocol==='http:'&&link.hostname==='creativecommons.org'){link.protocol='https:';licenseUrl=link.href}}
  if(!licenseUrl||new URL(licenseUrl).protocol!=='https:')return null;
  return {url,sourceUrl,credit,license,licenseUrl};
 }catch{return null}
}
export function messierArticleTitle(designation:string){const match=/^M\s*(\d+)$/i.exec(designation);return match?`Messier ${Number(match[1])}`:designation}
