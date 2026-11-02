import {commonsImage,messierArticleTitle} from "../../../../lib/object-media.ts";
import { plainArticleText } from "../../../../lib/article-text.ts";
import catalog from "../../../../generated/catalog.json";
import overlays from "../../../../generated/overlays.json";
import sun from "../../../../generated/sun-content.json";
type Language = "tr" | "en";
const titles:Record<string,Record<Language,string>>={sun:{tr:"Güneş",en:"Sun"},moon:{tr:"Ay",en:"Moon"},mercury:{tr:"Merkür",en:"Mercury_(planet)"},venus:{tr:"Venüs",en:"Venus"},mars:{tr:"Mars",en:"Mars"},jupiter:{tr:"Jüpiter",en:"Jupiter"},saturn:{tr:"Satürn",en:"Saturn"},uranus:{tr:"Uranüs",en:"Uranus"},neptune:{tr:"Neptün",en:"Neptune"}};
const cache=new Map<string,{expires:number;value:unknown}>(),inflight=new Map<string,Promise<unknown>>();
const clean = plainArticleText;
async function query(url:URL){const response=await fetch(url,{headers:{"User-Agent":"Yorungez/0.2 (astronomy object information)","Accept":"application/json"},signal:AbortSignal.timeout(5000)});if(!response.ok)throw new Error("upstream");return response.json();}
async function article(title:string,language:Language){
  const url=new URL(`https://${language}.wikipedia.org/w/api.php`);
  url.search=new URLSearchParams({action:"query",prop:"extracts|pageimages|info|revisions|pageprops",exintro:"1",explaintext:"1",exchars:"900",piprop:"name",inprop:"url",rvprop:"ids|timestamp",titles:title,redirects:"1",format:"json",formatversion:"2"}).toString();
  const page=(await query(url)).query.pages[0];
  if(page.missing||page.pageprops?.disambiguation!==undefined||!page.extract)throw new Error("missing");
  let image=null;
  if(page.pageimage){
    try{
      const commons=new URL("https://commons.wikimedia.org/w/api.php");commons.search=new URLSearchParams({action:"query",prop:"imageinfo",iiprop:"url|extmetadata|mime",iiurlwidth:"640",titles:`File:${page.pageimage}`,format:"json",formatversion:"2"}).toString();
      image=commonsImage((await query(commons)).query.pages[0].imageinfo?.[0]);
    }catch{/* Missing image rights never blocks the attributed text or map. */}
  }
  return {title:page.title,extract:clean(page.extract),url:page.fullurl,revision:page.revisions?.[0]?.revid,fetchedAtUtc:new Date().toISOString(),license:"CC BY-SA 4.0",licenseUrl:"https://creativecommons.org/licenses/by-sa/4.0/",credit:"Wikipedia contributors",image};
}
export async function GET(request:Request,{params}:{params:Promise<{id:string}>}){
  const {id}=await params,language:Language=new URL(request.url).searchParams.get("lang")==="tr"?"tr":"en";
  const headers={"Cache-Control":"public, max-age=3600","Content-Language":language};
  if(id==="sun")return Response.json({...sun[language],extract:sun[language].extract.split("\n")[0]},{headers});
  let title=titles[id]?.[language];
  if(!title){const star=catalog.stars.find(s=>s.id===id);if(star?.name&&!star.name.startsWith("HYG "))title=star.name;}
  if(!title){const dso=overlays.deepSky.find(o=>o.id===id);if(dso)title=messierArticleTitle(dso.name);}
  if(!title){const con=catalog.constellations.find(c=>c.id===id);if(con)title=language==="tr"?`${con.names.tr} (takımyıldız)`:`${con.names.en} (constellation)`;}
  if(!title)return Response.json({code:"Catalog.NoArticle"},{status:404,headers});
  const key=`${language}:${id}`,existing=cache.get(key);if(existing&&existing.expires>Date.now())return Response.json(existing.value,{headers});
  if(inflight.size>=4&&!inflight.has(key))return Response.json({code:"Catalog.ArticleBusy"},{status:503,headers:{...headers,"Cache-Control":"no-store","Retry-After":"2"}});
  try{let pending=inflight.get(key);if(!pending){pending=article(title,language);inflight.set(key,pending);}
    const result=await pending;if(cache.size>=128)cache.delete(cache.keys().next().value!);cache.set(key,{expires:Date.now()+86400000,value:result});return Response.json(result,{headers});
  }catch{return Response.json({code:"Catalog.ArticleUnavailable"},{status:503,headers:{...headers,"Cache-Control":"no-store"}});}
  finally{inflight.delete(key);}
}
