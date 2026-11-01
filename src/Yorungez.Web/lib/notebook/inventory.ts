import {localToUtc} from '../location/time.ts';
import type {NotebookLocation} from './model.ts';
import type {ObserverContext} from '../sky/types.ts';

export function locationSnapshot(source:NotebookLocation|ObserverContext):NotebookLocation{
 return {latitude:source.latitude,longitude:source.longitude,elevationMeters:source.elevationMeters,placeName:source.placeName||undefined};
}
export function observerAtSavedLocation(location:NotebookLocation,current:ObserverContext):ObserverContext{
 return {...locationSnapshot(location),instantUtc:current.instantUtc,source:'manual'};
}
export function enteredLocation(latitude:string,longitude:string,height:string,name:string):NotebookLocation{
 const number=(v:string)=>{if(!v.trim())throw new Error('location');const n=Number(v.trim().replace(',','.'));if(!Number.isFinite(n))throw new Error('location');return n};
 const lat=number(latitude),lon=number(longitude),elevationMeters=height.trim()?number(height):null;
 if(Math.abs(lat)>90||Math.abs(lon)>180||(elevationMeters!==null&&(elevationMeters< -500||elevationMeters>10000))||name.length>200)throw new Error('location');
 return {latitude:lat,longitude:lon,elevationMeters,placeName:name.trim()||undefined};
}
/** Empty means unknown. No map or creation timestamp is inferred as an actual observation. */
export function enteredObservationTime(date:string,hour:string,minute:string,zone:string,occurrence:'reject'|'earlier'|'later'='reject'){
 if(!date||!/^\d{1,2}$/.test(hour)||!/^\d{1,2}$/.test(minute)||Number(hour)>23||Number(minute)>59)throw new Error('observation-time');
 return localToUtc(`${date}T${hour.padStart(2,'0')}:${minute.padStart(2,'0')}`,zone,occurrence);
}
