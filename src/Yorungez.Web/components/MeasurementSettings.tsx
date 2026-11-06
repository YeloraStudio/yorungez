"use client";
export default function MeasurementSettings({language}:{language:'en'|'tr'}){return <button type="button" className="secondary-button" onClick={()=>window.dispatchEvent(new Event('yorungez:measurement-settings'))}>{language==='tr'?'Ölçüm tercihini değiştir':'Change analytics choice'}</button>;}
