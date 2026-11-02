import {readHeading,type OrientationSample} from './compass.ts';
export const sensorNames=['accelerometer','gyroscope','magnetometer'] as const;
export type SensorAccess='granted'|'denied'|'prompt'|'unknown';
export type SampleStatus='none'|'usable'|'relative'|'tilted'|'invalid';
export interface CompassAccess {secure:boolean;orientation:boolean;request:'not-required'|'pending'|'granted'|'denied'|'error';error:string;policyBlocked:boolean;sensors:Record<typeof sensorNames[number],SensorAccess>;sample:SampleStatus}
export function sampleStatus(sample:OrientationSample,angle:number):SampleStatus{
 if(readHeading(sample,angle))return 'usable';
 if(sample.beta!==null&&sample.gamma!==null&&Number.isFinite(sample.beta)&&Number.isFinite(sample.gamma)&&(Math.abs(sample.beta)>35||Math.abs(sample.gamma)>35))return 'tilted';
 if(sample.alpha!==null&&Number.isFinite(sample.alpha)&&!sample.absolute&&!Number.isFinite(sample.webkitCompassHeading))return 'relative';
 return 'invalid';
}
export function safePermissionError(error:unknown){const name=error instanceof Error?error.name:'';return ['NotAllowedError','SecurityError','NotSupportedError','TypeError'].includes(name)?name:'Error'}
export async function sensorAccess(query:((name:string)=>Promise<{state:string}>)|undefined){
 const pairs=await Promise.all(sensorNames.map(async name=>{let state:SensorAccess='unknown';try{const value=await query?.(name);if(value&&['granted','denied','prompt'].includes(value.state))state=value.state as SensorAccess}catch{/* Permission introspection is not supported consistently. */}return [name,state] as const}));
 return Object.fromEntries(pairs) as CompassAccess['sensors'];
}
