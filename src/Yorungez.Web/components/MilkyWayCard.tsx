"use client";
import featureData from '../generated/sky-features.json';
import ObjectCardShell from './ObjectCardShell';
import ObjectVisual from './ObjectVisual';
import type {Language,SkyCatalog} from '../lib/sky/types.ts';
import type {SkyFrame} from '../lib/sky/frame-contract.ts';
export default function MilkyWayCard({language,catalog,frame,onClose,onRegion,compact,onExpand,onCollapse}:{language:Language;catalog:SkyCatalog;frame:SkyFrame|null;onClose:()=>void;onRegion:()=>void;compact:boolean;onExpand:()=>void;onCollapse:()=>void}){
 const f=featureData.milkyWay,tr=language==='tr';
 return <ObjectCardShell id={f.id} name={f.names[language]} category={tr?'Galaksi':'Galaxy'} subtitle={tr?'İçinde bulunduğumuz galaksi':'Our home galaxy'} closeLabel={tr?'Bilgi kartını kapat':'Close information card'} onClose={onClose} compact={compact} language={language} onExpand={onExpand} onCollapse={onCollapse}>
  <ObjectVisual object={{id:f.id,name:f.names[language],kind:'extended',index:-1}} catalog={catalog} frame={frame} language={language} image={f.image} alwaysCredit/>
  <div className="object-about"><p>{f.description[language]}</p></div>
  <p className="muted">{f.region[language]}</p>
  <button type="button" className="primary-button focus-object" disabled={!frame?.canPublishAzimuth} onClick={onRegion}>{tr?'Yay bölgesini incele':'Explore Sagittarius region'} ↗</button>
  <p className="muted compact">{tr?'Panorama farklı zamanlarda çekilmiş görüntülerin birleşimidir; haritanın anlık görüntüsü veya dışarıdan galaksi fotoğrafı değildir.':'The panorama combines images taken at different times. It is not the current map or a photograph from outside the galaxy.'}</p>
  <details className="physical-details"><summary>{tr?'Bilgi kaynakları':'Information sources'}</summary><ul>{f.sources.map(s=><li key={s.url}><a href={s.url} target="_blank" rel="noopener noreferrer">{s.label} ↗</a></li>)}</ul></details>
 </ObjectCardShell>;
}
