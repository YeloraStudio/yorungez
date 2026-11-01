"use client";
import {useLayoutEffect,useRef,type RefObject,type ReactNode,type KeyboardEvent} from 'react';

/** A custom-painted top-layer popup also works inside the map's modal dialog. */
export default function PickerPopover({id,anchor,onClose,children,label,width=320,initialFocus,role='dialog'}:{
 id:string;anchor:RefObject<HTMLButtonElement|null>;onClose:(restore?:boolean)=>void;
 children:ReactNode;label:string;width?:number;initialFocus:string;role?:'dialog'|'presentation';
}){
 const host=useRef<HTMLDivElement>(null),close=useRef(onClose);close.current=onClose;
 useLayoutEffect(()=>{
  const popup=host.current!,trigger=anchor.current!;
  if(typeof popup.showPopover==='function')popup.showPopover();else popup.removeAttribute('popover');
  const position=()=>{const rect=trigger.getBoundingClientRect(),w=Math.min(width,window.innerWidth-24),availableBelow=window.innerHeight-rect.bottom-12;
   popup.style.width=w+'px';popup.style.left=Math.max(12,Math.min(rect.left,window.innerWidth-w-12))+'px';
   popup.style.maxHeight=Math.max(160,window.innerHeight-24)+'px';
   const height=Math.min(popup.scrollHeight,window.innerHeight-24);
   popup.style.top=Math.max(12,availableBelow>=height?rect.bottom+6:rect.top-height-6)+'px';
  };
  position();const focused=popup.querySelector<HTMLElement>(initialFocus)??popup.querySelector<HTMLElement>('button,input');focused?.focus({preventScroll:true});const list=focused?.closest<HTMLElement>('[role=listbox]');if(focused&&list)list.scrollTop+=focused.getBoundingClientRect().top-list.getBoundingClientRect().top-(list.clientHeight-focused.clientHeight)/2;
  const outside=(event:PointerEvent)=>{if(!popup.contains(event.target as Node)&&!trigger.contains(event.target as Node))close.current(false)};
  const focus=(event:FocusEvent)=>{if(!popup.contains(event.target as Node)&&!trigger.contains(event.target as Node))close.current(false)};
  document.addEventListener('pointerdown',outside);document.addEventListener('focusin',focus);window.addEventListener('resize',position);document.addEventListener('scroll',position,true);
  return()=>{document.removeEventListener('pointerdown',outside);document.removeEventListener('focusin',focus);window.removeEventListener('resize',position);document.removeEventListener('scroll',position,true);if(typeof popup.hidePopover==='function'&&popup.matches(':popover-open'))popup.hidePopover()};
 },[anchor,initialFocus,width]);
 function key(event:KeyboardEvent){if(event.key==='Escape'){event.preventDefault();event.stopPropagation();close.current(true)}else if(event.key==='Tab'){event.stopPropagation();}}
 return <div ref={host} id={id} popover="manual" className="picker-popover" role={role} aria-label={role==='dialog'?label:undefined} onKeyDown={key}>{children}</div>;
}
