"use client";
import type {Language} from '../../lib/sky/types.ts';

export default function CollapseToggle({expanded,controls,label,language,onToggle}:{expanded:boolean;controls:string;label:string;language:Language;onToggle:()=>void}){
 const action=language==='tr'?(expanded?'Küçült':'Genişlet'):(expanded?'Collapse':'Expand');
 return <button type="button" className="collapse-toggle icon-button" aria-expanded={expanded} aria-controls={controls} aria-label={`${label} · ${action}`} title={`${label} · ${action}`} onClick={onToggle}>
  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true"><path d={expanded?'m6 15 6-6 6 6':'m6 9 6 6 6-6'}/></svg>
 </button>;
}
