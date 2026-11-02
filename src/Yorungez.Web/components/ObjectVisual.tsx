"use client";
import {useMemo,useState} from 'react';
import type {ArchiveImage} from '../lib/object-media.ts';
import type {SelectedObject} from './ObjectCard';
import type {SkyCatalog,Language} from '../lib/sky/types.ts';
import type {SkyFrame} from '../lib/sky/frame-contract.ts';
import {finderField} from '../lib/sky/finder-field.ts';
export const visualText={
 en:{archive:'Archive image',chart:'Calculated sky view',loading:'Loading archive image…',unavailable:'Archive image unavailable',retry:'Retry image',source:'Image source and credit',notice:'Archival/processed image; not the selected date, current phase or naked-eye appearance.',chartHelp:'A position chart from the same calculation as the map. It is not a photograph.',pending:'Waiting for a validated position',withheld:'Direction is withheld in this polar region',noArticle:'No encyclopedia entry is linked yet. Catalogue information is available below.',moonPhase:'Archive photograph; not the current lunar phase.',field:'Field',photo:'Sourced archive image of'},
 tr:{archive:'Arşiv görüntüsü',chart:'Hesaplanan gökyüzü kesiti',loading:'Arşiv görüntüsü yükleniyor…',unavailable:'Arşiv görüntüsü alınamadı',retry:'Görseli yeniden dene',source:'Görsel kaynağı ve atıf',notice:'İşlenmiş/arşiv görüntüsüdür; seçili tarihi, güncel evreyi veya çıplak göz görünümünü göstermez.',chartHelp:'Haritayla aynı hesaptan üretilen konum çizimidir. Fotoğraf değildir.',pending:'Doğrulanmış konum bekleniyor',withheld:'Bu kutup bölgesinde yön sunulmuyor',noArticle:'Henüz bağlı bir ansiklopedi maddesi yok. Katalog bilgileri aşağıda.',moonPhase:'Arşiv fotoğrafı; güncel Ay evresi değildir.',field:'Görüş alanı',photo:'Kaynaklı arşiv görüntüsü:'}
} as const;
export default function ObjectVisual({object,catalog,frame,language,image,alwaysCredit=false}:{object:SelectedObject|{id:string;name:string;kind:'extended';index:-1};catalog:SkyCatalog;frame:SkyFrame|null;language:Language;image:ArchiveImage|null;alwaysCredit?:boolean}){
 const t=visualText[language],[loaded,setLoaded]=useState(''),[failed,setFailed]=useState(''),[attempt,setAttempt]=useState(0),src=image?.url??'',ready=!!src&&loaded===src&&failed!==src;
 const extended=object.kind==='extended';
 const chart=useMemo(()=>ready||extended?null:finderField(catalog,frame,object.index,object.kind==='constellation'?60:20),[ready,extended,catalog,frame,object.index,object.kind]);
 const chartLabel=extended?(language==='tr'?'Gökyüzüne yayılan galaksi':'Extended sky feature'):chart?t.chart:frame&&!frame.canPublishAzimuth?t.withheld:t.pending;
 return <figure className="object-visual" data-visual-kind={ready?'archive':'chart'}>
  <div className="object-visual-stage">
   {!ready&&<svg viewBox="0 0 360 210" role="img" aria-label={`${object.name} · ${chartLabel}`}><rect width="360" height="210" fill="#15171b"/>{!extended&&<path d="M0 105H360M180 0V210" stroke="#9EA1A6" strokeOpacity=".16"/>}{chart?.points.map(point=><circle key={point.id} cx={point.x} cy={point.y} r={Math.max(.7,2.3-point.magnitude*.22)} fill="#F7F1E6" opacity={Math.max(.35,1-point.magnitude*.08)}/>)}{chart&&<><circle cx="180" cy="105" r="13" stroke="#C9B6A6" fill="none" strokeDasharray="3 4"/><path d="M180 81V88M180 122V129M156 105H163M197 105H204" stroke="#C9B6A6"/></>}{chart&&<text x="12" y="194" fill="#9EA1A6" fontSize="11">{t.field} {chart.fieldOfView}°</text>}</svg>}
   {image&&failed!==src&&<img key={src+':'+attempt} src={src} alt={`${t.photo} ${object.name}`} decoding="async" onLoad={()=>setLoaded(src)} onError={()=>setFailed(src)} style={{visibility:ready?'visible':'hidden'}}/>}
   <span className="visual-kind">{ready?t.archive:chartLabel}</span>
  </div>
  <figcaption>
   <p>{ready?(object.id==='moon'?t.moonPhase:null):chart?t.chartHelp:chartLabel}</p>
   {src&&!ready&&<p className="muted" role="status">{failed===src?t.unavailable:t.loading}{failed===src&&<> · <button type="button" className="inline-term" onClick={()=>{setFailed('');setLoaded('');setAttempt(n=>n+1)}}>{t.retry}</button></>}</p>}
   {ready&&alwaysCredit&&image&&<p className="source-credit">{image.credit} · <a href={image.licenseUrl} target="_blank" rel="noopener noreferrer">{image.license}</a> · <a href={image.sourceUrl} target="_blank" rel="noopener noreferrer">{t.archive} ↗</a></p>}
   {ready&&image&&<details><summary>{t.source}</summary><p>{t.notice}</p><p>{image.credit} · <a href={image.licenseUrl} target="_blank" rel="noopener noreferrer">{image.license}</a><br/><a href={image.sourceUrl} target="_blank" rel="noopener noreferrer">{t.archive} ↗</a></p></details>}
  </figcaption>
 </figure>;
}
