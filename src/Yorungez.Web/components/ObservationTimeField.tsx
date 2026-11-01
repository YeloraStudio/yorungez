"use client";
import {Temporal} from '@js-temporal/polyfill';
import DateField from './ui/DateField';
import SelectField from './ui/SelectField';
import type {Language} from '../lib/sky/types.ts';

export interface ObservationTimeDraft {date:string;hour:string;minute:string;zone:string;occurrence:'reject'|'earlier'|'later'}
export function observationTimeDraft(initial?:string):ObservationTimeDraft {
 const prior=initial?Temporal.Instant.from(initial).toZonedDateTimeISO('UTC'):null;
 return {date:prior?.toPlainDate().toString()??'',hour:prior?String(prior.hour):'',minute:prior?String(prior.minute):'',zone:'UTC',occurrence:'reject'};
}
export default function ObservationTimeField({language,value,onChange}:{language:Language;value:ObservationTimeDraft;onChange:(value:ObservationTimeDraft)=>void}){
 const {date,hour,minute,zone,occurrence}=value;
 const tr=language==='tr',choose=tr?'Seç':'Choose',zones=[...new Set(['UTC',...(typeof Intl.supportedValuesOf==='function'?Intl.supportedValuesOf('timeZone'):[])])];
 return <fieldset className="date-time-field"><legend>{tr?'Gerçek gözlem zamanı (isteğe bağlı)':'Actual observation time (optional)'}</legend>
  <SelectField language={language} label={tr?'Girdi saat dilimi':'Input time zone'} value={zone} name="observedZone" searchable options={zones.map(value=>({value,label:value}))} onChange={zone=>onChange({...value,zone,occurrence:'reject'})}/>
  <DateField language={language} label={tr?'Gözlem tarihi':'Observation date'} name="observedDate" value={date} onChange={date=>onChange({...value,date})} min="0001-01-01" max={Temporal.Now.instant().toZonedDateTimeISO(zone).toPlainDate().toString()}/>
  <div className="clock-fields"><SelectField language={language} label={tr?'Gözlem saati':'Observation hour'} name="observedHour" value={hour} onChange={hour=>onChange({...value,hour})} options={[{value:'',label:choose},...Array.from({length:24},(_,i)=>({value:String(i),label:String(i).padStart(2,'0')}))]}/><span aria-hidden="true">:</span><SelectField language={language} label={tr?'Gözlem dakikası':'Observation minute'} name="observedMinute" value={minute} onChange={minute=>onChange({...value,minute})} options={[{value:'',label:choose},...Array.from({length:60},(_,i)=>({value:String(i),label:String(i).padStart(2,'0')}))]}/></div>
  {zone!=='UTC'&&<SelectField language={language} label={tr?'Tekrarlanan saat':'Repeated local time'} name="observedOccurrence" value={occurrence} onChange={occurrence=>onChange({...value,occurrence:occurrence as ObservationTimeDraft['occurrence']})} options={[{value:'reject',label:tr?'Belirsizse reddet':'Reject if ambiguous'},{value:'earlier',label:tr?'İlk oluşum':'First occurrence'},{value:'later',label:tr?'İkinci oluşum':'Second occurrence'}]}/>}
  <p className="muted compact">{tr?'Alanlar boş başlar. Seçtiğin yerel saat UTC anına dönüştürülür; yaz/kış saati boşluğu reddedilir. Harita zamanı veya kayıt oluşturma zamanı buraya otomatik yazılmaz.':'Fields start empty. Your entered local time is converted to a UTC instant; DST gaps are rejected. Map time and record creation time are never filled in as the observation time.'}</p>
 </fieldset>;
}
