"use client";
import {useId,type ReactNode} from 'react';
import CollapseToggle from './ui/CollapseToggle';
import type {Language} from '../lib/sky/types.ts';
export default function ObjectCardShell({id,name,category,subtitle,closeLabel,onClose,compact=false,onExpand,onCollapse,language,children}:{id:string;name:string;category:string;subtitle:string;closeLabel:string;onClose:()=>void;compact?:boolean;onExpand:()=>void;onCollapse:()=>void;language:Language;children:ReactNode}){
 const bodyId=useId();
 return <section id="object-panel" className={`object-card glass${compact?' compact-card':''}`} aria-labelledby="object-heading" data-object-id={id}>
  <div className="card-heading"><div><span className="eyebrow">{category}</span><h2 id="object-heading" tabIndex={-1}>{name}</h2><small className="catalog-id">{subtitle}</small></div><div className="card-heading-actions"><CollapseToggle language={language} label={name} expanded={!compact} controls={bodyId} onToggle={compact?onExpand:onCollapse}/><button className="icon-button" aria-label={closeLabel} onClick={onClose}>×</button></div></div>
  <div id={bodyId} className="object-card-body" hidden={compact}>{children}</div>
 </section>;
}
