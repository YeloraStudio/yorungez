"use client";
import {useLayoutEffect,useRef,type RefObject,type ReactNode,type KeyboardEvent} from 'react';
import {popupBounds} from '../../lib/viewport.ts';

/** A custom-painted top-layer popup also works inside the map's modal dialog. */
export default function PickerPopover({id,anchor,onClose,children,label,width=320,initialFocus,role='dialog'}:{
 id:string;anchor:RefObject<HTMLButtonElement|null>;onClose:(restore?:boolean)=>void;
 children:ReactNode;label:string;width?:number;initialFocus:string;role?:'dialog'|'presentation';
}){
 const host=useRef<HTMLDivElement>(null),close=useRef(onClose);close.current=onClose;
 useLayoutEffect(()=>{
  const popup=host.current!,trigger=anchor.current!;
  if(typeof popup.showPopover==='function')popup.showPopover();else popup.removeAttribute('popover');
  const visual=window.visualViewport;
  const position=()=>{const viewport={left:visual?.offsetLeft??0,top:visual?.offsetTop??0,width:visual?.width??window.innerWidth,height:visual?.height??window.innerHeight};
   let bounds=popupBounds(trigger.getBoundingClientRect(),viewport,width,popup.scrollHeight);
   popup.style.width=bounds.width+'px';popup.style.maxHeight=bounds.maxHeight+'px';
   bounds=popupBounds(trigger.getBoundingClientRect(),viewport,width,popup.scrollHeight);
   popup.style.left=bounds.left+'px';popup.style.top=bounds.top+'px';
  };
  position();const focused=popup.querySelector<HTMLElement>(initialFocus)??popup.querySelector<HTMLElement>('button,input');focused?.focus({preventScroll:true});const list=focused?.closest<HTMLElement>('[role=listbox]');if(focused&&list)list.scrollTop+=focused.getBoundingClientRect().top-list.getBoundingClientRect().top-(list.clientHeight-focused.clientHeight)/2;
  const outside=(event:PointerEvent)=>{if(!popup.contains(event.target as Node)&&!trigger.contains(event.target as Node))close.current(false)};
  const focus=(event:FocusEvent)=>{if(!popup.contains(event.target as Node)&&!trigger.contains(event.target as Node))close.current(false)};
  document.addEventListener('pointerdown',outside);document.addEventListener('focusin',focus);window.addEventListener('resize',position);document.addEventListener('scroll',position,true);visual?.addEventListener('resize',position);visual?.addEventListener('scroll',position);
  return()=>{document.removeEventListener('pointerdown',outside);document.removeEventListener('focusin',focus);window.removeEventListener('resize',position);document.removeEventListener('scroll',position,true);visual?.removeEventListener('resize',position);visual?.removeEventListener('scroll',position);if(typeof popup.hidePopover==='function'&&popup.matches(':popover-open'))popup.hidePopover()};
 },[anchor,initialFocus,width]);
 function key(event:KeyboardEvent){if(event.key==='Escape'){event.preventDefault();event.stopPropagation();close.current(true)}else if(event.key==='Tab'){event.stopPropagation();}}
 return <div ref={host} id={id} popover="manual" className="picker-popover" role={role} aria-label={role==='dialog'?label:undefined} onKeyDown={key}>{children}</div>;
}
