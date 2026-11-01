"use client";
import {useId,useRef,useState,type KeyboardEvent} from 'react';
import type {Language} from '../../lib/sky/types.ts';
import PickerPopover from './PickerPopover';
export interface SelectOption {value:string;label:string}
const normalized=(v:string)=>v.normalize('NFD').replace(/[\u0300-\u036f]/g,'').replace(/ı/g,'i').toLowerCase();
export default function SelectField({label,value,options,onChange,language,name,searchable=false,disabled=false}:{
 label:string;value:string;options:SelectOption[];onChange:(value:string)=>void;language:Language;name?:string;searchable?:boolean;disabled?:boolean;
}){
 const id=useId(),anchor=useRef<HTMLButtonElement>(null),[open,setOpen]=useState(false),[query,setQuery]=useState(''),buffer=useRef({text:'',time:0});
 const filtered=options.filter(o=>normalized(o.label).includes(normalized(query))),selected=options.find(o=>o.value===value);
 const close=(restore=true)=>{setOpen(false);if(restore)anchor.current?.focus({preventScroll:true})};
 const choose=(next:string)=>{onChange(next);close()};
 function keyboard(event:KeyboardEvent){
  if(event.key==='Escape'){event.preventDefault();event.stopPropagation();close();return}
  if(event.key==='Tab'){close();return}
  const popup=document.getElementById(id+'-popup'),buttons=Array.from(popup?.querySelectorAll<HTMLButtonElement>('[role=option]')??[]),index=buttons.indexOf(event.target as HTMLButtonElement);
  let next=-1;
  if(event.key==='ArrowDown')next=(index+1)%Math.max(1,buttons.length);
  else if(event.key==='ArrowUp')next=index<=0?buttons.length-1:index-1;
  else if(event.key==='Home'&&!(event.target instanceof HTMLInputElement))next=0;
  else if(event.key==='End'&&!(event.target instanceof HTMLInputElement))next=buttons.length-1;
  else if(!searchable&&event.key.length===1&&!event.ctrlKey&&!event.metaKey){const now=Date.now();buffer.current={text:(now-buffer.current.time<700?buffer.current.text:'')+event.key,time:now};next=filtered.findIndex(o=>normalized(o.label).startsWith(normalized(buffer.current.text)));}
  if(next>=0&&buttons[next]){event.preventDefault();buttons[next].focus()}
 }
 return <div className="select-field"><span id={id+'-label'} className="field-label">{label}</span>{name&&<input type="hidden" name={name} value={value}/>}
  <button ref={anchor} type="button" className="picker-trigger" role="combobox" aria-labelledby={id+'-label'} aria-haspopup={searchable?'dialog':'listbox'} aria-expanded={open} aria-controls={open?id+(searchable?'-popup':'-list'):undefined} disabled={disabled}
   onClick={()=>{setQuery('');setOpen(!open)}} onKeyDown={event=>{if(['ArrowDown','ArrowUp','Home','End'].includes(event.key)){event.preventDefault();setQuery('');setOpen(true)}}}>
   <span>{selected?.label??value}</span><span aria-hidden="true">⌄</span>
  </button>
  {open&&<PickerPopover id={id+'-popup'} anchor={anchor} label={label} role={searchable?'dialog':'presentation'} onClose={close} initialFocus={searchable?'input':'[aria-selected="true"]'} width={Math.max(220,anchor.current?.getBoundingClientRect().width??220)}>
   <div onKeyDown={keyboard}>{searchable&&<input className="picker-search" aria-label={language==='tr'?`${label} ara`:`Search ${label}`} placeholder={language==='tr'?'Listede ara…':'Search options…'} value={query} onChange={event=>setQuery(event.target.value)}/>}
    <ul id={id+'-list'} className="picker-options" role="listbox" aria-label={label}>{filtered.map(option=><li role="presentation" key={option.value}><button type="button" role="option" aria-selected={option.value===value} tabIndex={option.value===value?0:-1} onClick={()=>choose(option.value)}><span>{option.label}</span>{option.value===value&&<span aria-hidden="true">✓</span>}</button></li>)}</ul>
    {!filtered.length&&<p className="muted compact" role="status">{language==='tr'?'Sonuç yok.':'No results.'}</p>}
   </div>
  </PickerPopover>}
 </div>;
}
