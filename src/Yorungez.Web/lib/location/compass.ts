export interface OrientationSample {absolute?:boolean;alpha:number|null;beta:number|null;gamma:number|null;webkitCompassHeading?:number;webkitCompassAccuracy?:number}
export interface Heading {degrees:number;accuracy:number|null;source:'webkit'|'absolute'}
export const wrapDegrees=(n:number)=>((n%360)+360)%360;
// This tool reads the top edge of a FLAT phone, not the rear-camera optical axis.
// Relative alpha is deliberately rejected: it cannot identify north.
export function readHeading(e:OrientationSample,screenAngle=0):Heading|null{
 if(e.beta===null||e.gamma===null||!Number.isFinite(e.beta)||!Number.isFinite(e.gamma)||Math.abs(e.beta)>35||Math.abs(e.gamma)>35)return null;
 if(Number.isFinite(e.webkitCompassHeading)){
  if(e.webkitCompassAccuracy!==undefined&&(!Number.isFinite(e.webkitCompassAccuracy)||e.webkitCompassAccuracy<0||e.webkitCompassAccuracy>30))return null;
  return {degrees:wrapDegrees(e.webkitCompassHeading!+screenAngle),accuracy:e.webkitCompassAccuracy??null,source:'webkit'};
 }
 if(e.absolute&&e.alpha!==null&&Number.isFinite(e.alpha))return {degrees:wrapDegrees(360-e.alpha+screenAngle),accuracy:null,source:'absolute'};
 return null;
}
export type CompassState='idle'|'requesting'|'waiting'|'ready'|'denied'|'unsupported'|'insecure'|'unavailable';
export interface CompassPort {secure:boolean;supported:boolean;requestPermission?:()=>Promise<string>;subscribe:(cb:(sample:OrientationSample,screenAngle:number)=>void)=>()=>void}
export class HeadingSession{
 private generation=0;private unsubscribe:(()=>void)|undefined;private timer:ReturnType<typeof setTimeout>|undefined;
 private port:CompassPort;private state:(s:CompassState)=>void;private heading:(h:Heading)=>void;private timeout:number;
 constructor(port:CompassPort,state:(s:CompassState)=>void,heading:(h:Heading)=>void,timeout=8000){this.port=port;this.state=state;this.heading=heading;this.timeout=timeout;}
 async start(){this.stop(false);const generation=++this.generation;
  if(!this.port.secure){this.state('insecure');return;}if(!this.port.supported){this.state('unsupported');return;}
  this.state('requesting');
  try{if(this.port.requestPermission&&await this.port.requestPermission()!=='granted'){if(generation===this.generation)this.state('denied');return;}}catch{if(generation===this.generation)this.state('denied');return;}
  if(generation!==this.generation)return;
  this.state('waiting');
  this.timer=setTimeout(()=>{if(generation===this.generation){this.generation++;this.unsubscribe?.();this.unsubscribe=undefined;this.state('unavailable');}},this.timeout);
  try{this.unsubscribe=this.port.subscribe((event,angle)=>{if(generation!==this.generation)return;const value=readHeading(event,angle);if(value){clearTimeout(this.timer);this.timer=setTimeout(()=>{if(generation===this.generation){this.generation++;this.unsubscribe?.();this.unsubscribe=undefined;this.state('unavailable')}},this.timeout);this.heading(value);this.state('ready');}});}catch{clearTimeout(this.timer);this.state('unavailable');}
 }
 stop(report=true){this.generation++;clearTimeout(this.timer);this.unsubscribe?.();this.unsubscribe=undefined;if(report)this.state('idle');}
}
