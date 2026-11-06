import content from '../../../data/knowledge/guides.json';
export const guides=content.guides;
export const reviewed=content.reviewed;
export const editor=content.editor;
export const categories:Record<string,{en:string;tr:string}>={Observing:{en:'Observing',tr:'Gözlem'},Moon:{en:'Moon',tr:'Ay'},Planets:{en:'Planets',tr:'Gezegenler'},Basics:{en:'Basics',tr:'Temel bilgiler'},Constellations:{en:'Constellations',tr:'Takımyıldızlar'},Galaxies:{en:'Galaxies',tr:'Gökadalar'},Time:{en:'Time',tr:'Zaman'}};
