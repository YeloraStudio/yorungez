import type {ObserverContext} from './types.ts';
export type CalculationStatus='waiting'|'error'|'updating'|'live'|'simulation'|'delayed';
/** Freshness is a display diagnostic, not an astrometric accuracy tolerance. */
export function calculationStatus(frame:ObserverContext|null,requested:ObserverContext,mode:'live'|'simulation',error:boolean,now:number):CalculationStatus{
 if(error)return 'error';
 if(!frame)return 'waiting';
 if(frame.latitude!==requested.latitude||frame.longitude!==requested.longitude||frame.elevationMeters!==requested.elevationMeters)return 'updating';
 if(mode==='simulation')return frame.instantUtc===requested.instantUtc?'simulation':'updating';
 const time=Date.parse(frame.instantUtc);
 return !Number.isFinite(time)||Math.abs(now-time)>10000?'delayed':'live';
}
