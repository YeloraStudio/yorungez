import {Temporal} from '@js-temporal/polyfill';
export function clampDate(value:string,min:string,max:string){const day=Temporal.PlainDate.from(value).toString();return day<min?min:day>max?max:day;}
export function monthGrid(value:string){const month=Temporal.PlainDate.from(value).with({day:1}),first=month.subtract({days:month.dayOfWeek-1});return Array.from({length:42},(_,i)=>first.add({days:i}));}
export function moveCalendarDay(value:string,key:string,shift=false){const day=Temporal.PlainDate.from(value);switch(key){
 case 'ArrowLeft':return day.subtract({days:1}).toString();case 'ArrowRight':return day.add({days:1}).toString();case 'ArrowUp':return day.subtract({days:7}).toString();case 'ArrowDown':return day.add({days:7}).toString();
 case 'Home':return day.subtract({days:day.dayOfWeek-1}).toString();case 'End':return day.add({days:7-day.dayOfWeek}).toString();case 'PageUp':return day.subtract(shift?{years:1}:{months:1}).toString();case 'PageDown':return day.add(shift?{years:1}:{months:1}).toString();default:return null;
}}
