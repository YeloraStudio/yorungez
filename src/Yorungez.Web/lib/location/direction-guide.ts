import {wrapDegrees} from './compass.ts';
export function cardinalIndex(azimuth:number){if(!Number.isFinite(azimuth))throw new RangeError('invalid-direction');return Math.round(wrapDegrees(azimuth)/45)%8;}
export function observingBrief(target:{id:string;altitude:number},sunAltitude:number|null){
 if(target.id==='sun')return 'solar';
 if(!Number.isFinite(target.altitude))return 'unknown';
 if(target.altitude<0)return 'below';
 if(sunAltitude===null||!Number.isFinite(sunAltitude))return 'unknown';
 if(sunAltitude>=-6)return 'twilight';
 return 'night';
}
export const angularFists=(altitude:number)=>Math.round(Math.max(0,Math.min(90,altitude))/5)/2;
