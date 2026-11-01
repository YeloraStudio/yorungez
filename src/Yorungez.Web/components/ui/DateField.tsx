"use client";
import {useId,useRef,useState,useLayoutEffect} from 'react';
import {Temporal} from '@js-temporal/polyfill';
import {clampDate,monthGrid,moveCalendarDay} from '../../lib/date-picker.ts';
import type {Language} from '../../lib/sky/types.ts';
import PickerPopover from './PickerPopover';import SelectField from './SelectField';
export default function DateField({label,value,onChange,language,name,min='2000-01-01',max='2035-12-31'}:{label:string;value:string;onChange:(value:string)=>void;language:Language;name?:string;min?:string;max?:string}){
 const initial=()=>clampDate(value||Temporal.Now.plainDateISO().toString(),min,max);
 const id=useId(),anchor=useRef<HTMLButtonElement>(null),[open,setOpen]=useState(false),[cursor,setCursor]=useState(initial),grid=useRef<HTMLTableElement>(null);
 const [focusDay,setFocusDay]=useState(false),day=Temporal.PlainDate.from(cursor),cells=monthGrid(cursor),minimum=Temporal.PlainDate.from(min),maximum=Temporal.PlainDate.from(max);
 const text=language==='tr'?{previous:'Önceki ay',next:'Sonraki ay',month:'Ay',year:'Yıl',close:'Kapat',help:'Oklar: gün/hafta · Home/End: hafta sınırı · Page Up/Down: ay · Shift: yıl · Enter: seç · Esc: kapat'}:{previous:'Previous month',next:'Next month',month:'Month',year:'Year',close:'Close',help:'Arrows: day/week · Home/End: week boundary · Page Up/Down: month · Shift: year · Enter: select · Esc: close'};
 const format=(d:string,style:'medium'|'full'='medium')=>new Intl.DateTimeFormat(language,{timeZone:'UTC',dateStyle:style}).format(new Date(d+'T12:00:00Z'));
 const monthName=(n:number)=>new Intl.DateTimeFormat(language,{timeZone:'UTC',month:'long'}).format(new Date(Date.UTC(2026,n-1,1)));
 useLayoutEffect(()=>{if(open&&focusDay){grid.current?.querySelector<HTMLButtonElement>(`[data-day="${cursor}"]`)?.focus({preventScroll:true});setFocusDay(false)}},[cursor,open,focusDay]);
 const close=(restore=true)=>{setOpen(false);if(restore)anchor.current?.focus({preventScroll:true})};
 const move=(next:string,focus=false)=>{setCursor(clampDate(next,min,max));if(focus)setFocusDay(true)};
 return <div className="date-field"><span className="field-label">{label}</span>{name&&<input type="hidden" name={name} value={value}/>}
  <button type="button" ref={anchor} className="picker-trigger date-trigger" aria-label={`${label}: ${value?format(value):language==='tr'?'Tarih seç':'Choose a date'}`} aria-haspopup="dialog" aria-expanded={open} aria-controls={open?id:undefined} onClick={()=>{setCursor(initial());setOpen(!open)}}><span>{value?format(value):language==='tr'?'Tarih seç':'Choose a date'}</span><span aria-hidden="true">▦</span></button>
  {open&&<PickerPopover id={id} anchor={anchor} label={label} onClose={close} width={342} initialFocus={`[data-day="${initial()}"]`}>
   <div className="date-picker-heading"><button type="button" className="calendar-step" aria-label={text.previous} disabled={day.with({day:1}).toString()<=minimum.with({day:1}).toString()} onClick={()=>move(day.subtract({months:1}).toString())}>‹</button>
    <SelectField language={language} label={text.month} value={String(day.month)} options={Array.from({length:12},(_,i)=>({value:String(i+1),label:monthName(i+1)}))} onChange={v=>move(day.with({month:Number(v)}).toString())}/>
    <SelectField language={language} label={text.year} value={String(day.year)} options={Array.from({length:maximum.year-minimum.year+1},(_,i)=>({value:String(minimum.year+i),label:String(minimum.year+i)}))} searchable onChange={v=>move(day.with({year:Number(v)}).toString())}/>
    <button type="button" className="calendar-step" aria-label={text.next} disabled={day.with({day:1}).toString()>=maximum.with({day:1}).toString()} onClick={()=>move(day.add({months:1}).toString())}>›</button>
   </div>
   <p className="calendar-caption" aria-live="polite">{monthName(day.month)} {day.year}</p>
   <table ref={grid} className="date-grid" role="grid" aria-label={`${monthName(day.month)} ${day.year}`} onKeyDown={event=>{const next=moveCalendarDay(cursor,event.key,event.shiftKey);if(next){event.preventDefault();event.stopPropagation();move(next,true)}}}>
    <thead><tr>{Array.from({length:7},(_,i)=>{const d=new Date(Date.UTC(2026,5,1+i));return <th key={i} scope="col" abbr={new Intl.DateTimeFormat(language,{weekday:'long',timeZone:'UTC'}).format(d)}>{new Intl.DateTimeFormat(language,{weekday:'short',timeZone:'UTC'}).format(d)}</th>})}</tr></thead>
    <tbody>{Array.from({length:6},(_,week)=><tr key={week}>{cells.slice(week*7,week*7+7).map(cell=>{const v=cell.toString(),selected=v===value;return <td key={v} role="gridcell" aria-selected={selected}><button data-day={v} type="button" tabIndex={v===cursor?0:-1} className={cell.month===day.month?'':'other-month'} disabled={v<min||v>max} aria-label={format(v,'full')} data-selected={selected} onClick={()=>{onChange(v);close()}}>{cell.day}</button></td>})}</tr>)}</tbody>
   </table><p className="picker-help">{text.help}</p><button type="button" className="picker-close" onClick={()=>close()}>{text.close}</button>
  </PickerPopover>}
 </div>;
}
