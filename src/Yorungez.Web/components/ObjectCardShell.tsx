"use client";
import type {ReactNode} from 'react';
export default function ObjectCardShell({id,name,category,subtitle,closeLabel,onClose,compact=false,restoreLabel,onExpand,children}:{id:string;name:string;category:string;subtitle:string;closeLabel:string;onClose:()=>void;compact?:boolean;restoreLabel?:string;onExpand?:()=>void;children:ReactNode}){
 return <section id="object-panel" className={`object-card glass${compact?' compact-card':''}`} aria-labelledby="object-heading" data-object-id={id}>
  <div className="card-heading"><div><span className="eyebrow">{category}</span><h2 id="object-heading" tabIndex={-1}>{name}</h2><small className="catalog-id">{subtitle}</small></div><button className="icon-button" aria-label={closeLabel} onClick={onClose}>×</button></div>
  {compact&&<button className="card-restore secondary-button" onClick={onExpand}>{restoreLabel} ↗</button>}
  <div className="object-card-body">{children}</div>
 </section>;
}
