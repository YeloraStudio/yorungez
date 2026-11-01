"use client";
import {useState} from 'react';import {Temporal} from '@js-temporal/polyfill';
import type {Language} from '../../lib/sky/types.ts';import DateField from './DateField';import SelectField from './SelectField';
/** Local draft lives here: the live sky clock must never overwrite an in-progress form. */
export default function DateTimeField({label,defaultValue,name,language,onChange}:{label:string;defaultValue:string;name:string;language:Language;onChange?:()=>void}){
 const [draft,setDraft]=useState(()=>Temporal.PlainDateTime.from(defaultValue)),date=draft.toPlainDate().toString();
 const change=(next:Temporal.PlainDateTime)=>{setDraft(next);onChange?.()};
 return <fieldset className="date-time-field"><legend>{label}</legend><input type="hidden" name={name} value={draft.toString({smallestUnit:'minute'})}/>
  <DateField label={language==='tr'?'Tarih':'Date'} language={language} value={date} onChange={v=>change(Temporal.PlainDate.from(v).toPlainDateTime(draft.toPlainTime()))}/>
  <div className="clock-fields"><SelectField language={language} label={language==='tr'?'Saat':'Hour'} value={String(draft.hour)} options={Array.from({length:24},(_,i)=>({value:String(i),label:String(i).padStart(2,'0')}))} onChange={v=>change(draft.with({hour:Number(v)}))}/><span aria-hidden="true">:</span>
   <SelectField language={language} label={language==='tr'?'Dakika':'Minute'} value={String(draft.minute)} options={Array.from({length:60},(_,i)=>({value:String(i),label:String(i).padStart(2,'0')}))} onChange={v=>change(draft.with({minute:Number(v)}))}/>
  </div>
 </fieldset>;
}
