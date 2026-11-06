import photos from '../generated/object-photos.json';
import features from '../generated/sky-features.json';
const imageKeys:Record<string,keyof typeof photos>={'moon-phases':'moon','find-jupiter':'jupiter','stars-and-planets':'hyg-32263','milky-way-and-andromeda':'dso-ngc0224'};
const names:Record<string,{en:string;tr:string}>={moon:{en:'The Moon',tr:'Ay'},jupiter:{en:'Jupiter',tr:'Jüpiter'},'hyg-32263':{en:'Sirius A and B',tr:'Sirius A ve B'},'dso-ngc0224':{en:'Andromeda Galaxy',tr:'Andromeda Gökadası'}};
export default function GuideImage({slug,language}:{slug:string;language:'en'|'tr'}){
 const key=imageKeys[slug];const image=slug==='plan-a-dark-sky-night'?features.milkyWay.image:key?photos[key]:null;
 if(!image)return null;
 const name=slug==='plan-a-dark-sky-night'?features.milkyWay.names[language]:names[key][language];
 return <figure className="guide-image"><img src={image.url} alt={name} width="760" height="360" decoding="async"/><figcaption><strong>{name}</strong> · {language==='tr'?'Arşiv görseli; canlı gözlem veya çıplak göz parlaklığı değildir.':'Archive image; not a live observation or naked-eye brightness.'}<br/>{image.credit} · <a href={image.sourceUrl}>{language==='tr'?'Kaynak':'Source'} ↗</a> · <a href={image.licenseUrl}>{image.license}</a></figcaption></figure>;
}
