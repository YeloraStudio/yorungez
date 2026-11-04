import {wrapDegrees,type OrientationSample} from './compass.ts';
export interface PhonePose {azimuth:number;altitude:number;roll:number;reference:'absolute'|'relative';accuracy:number|null}
const RAD=Math.PI/180;
// W3C intrinsic Z-X'-Y'' rotation, ENU world. Rear optical axis is device -Z.
// No claim that an absolute browser reference is calibrated true north.
export function rearCameraPose(e:OrientationSample,screenAngle=0):PhonePose|null{
 if([e.alpha,e.beta,e.gamma].some(v=>v===null||!Number.isFinite(v))||!Number.isFinite(screenAngle))return null;
 if(Math.abs(e.beta!)>180||Math.abs(e.gamma!)>90||e.alpha!<0||e.alpha!>360)return null;
 if(e.webkitCompassAccuracy!==undefined&&(!Number.isFinite(e.webkitCompassAccuracy)||e.webkitCompassAccuracy<0||e.webkitCompassAccuracy>30))return null;
 const a=e.alpha!*RAD,b=e.beta!*RAD,g=e.gamma!*RAD,s=screenAngle*RAD;
 const ca=Math.cos(a),sa=Math.sin(a),cb=Math.cos(b),sb=Math.sin(b),cg=Math.cos(g),sg=Math.sin(g);
 const x=[ca*cg-sa*sb*sg,sa*cg+ca*sb*sg,-cb*sg],y=[-cb*sa,ca*cb,sb];
 const forward=[-cg*sa*sb-ca*sg,-sa*sg+ca*cg*sb,-cb*cg];
 const up=y.map((v,i)=>v*Math.cos(s)+x[i]*Math.sin(s));
 const horizontal=Math.hypot(forward[0],forward[1]);
 const az=horizontal>1e-7?Math.atan2(forward[0],forward[1]):Math.atan2(-up[0],-up[1]);
 const alt=Math.atan2(forward[2],horizontal),right=[Math.cos(az),-Math.sin(az),0],vertical=[-Math.sin(alt)*Math.sin(az),-Math.sin(alt)*Math.cos(az),Math.cos(alt)];
 const dot=(v:number[],w:number[])=>v.reduce((sum,n,i)=>sum+n*w[i],0);
 return {azimuth:wrapDegrees(az/RAD),altitude:alt/RAD,roll:Math.atan2(dot(up,right),dot(up,vertical))/RAD,
  reference:e.absolute?'absolute':'relative',accuracy:e.webkitCompassAccuracy??null};
}
export type PointingState='idle'|'requesting'|'waiting'|'align'|'tracking'|'denied'|'unsupported'|'insecure'|'unavailable';
export interface PointingPort {secure:boolean;supported:boolean;requestPermission?:()=>Promise<string>;subscribe:(cb:(e:OrientationSample,angle:number)=>void)=>()=>void}
export class PointingSession{
 private generation=0;private off:(()=>void)|undefined;private timer:ReturnType<typeof setTimeout>|undefined;
 private pose:PhonePose|null=null;private offset:number|null=null;private reference:PhonePose['reference']|null=null;
 private port:PointingPort;private state:(s:PointingState)=>void;private sample:(p:PhonePose)=>void;private apply:(p:PhonePose)=>void;private timeout:number;
 constructor(port:PointingPort,state:(s:PointingState)=>void,sample:(p:PhonePose)=>void,apply:(p:PhonePose)=>void,timeout=8000){this.port=port;this.state=state;this.sample=sample;this.apply=apply;this.timeout=timeout}
 async start(){this.stop(false);const seq=++this.generation;
  if(!this.port.secure){this.state('insecure');return}if(!this.port.supported){this.state('unsupported');return}
  this.state('requesting');
  try{if(this.port.requestPermission&&await this.port.requestPermission()!=='granted'){if(seq===this.generation)this.state('denied');return}}
  catch{if(seq===this.generation)this.state('denied');return}
  if(seq!==this.generation)return;this.state('waiting');this.arm(seq);
  try{this.off=this.port.subscribe((e,angle)=>{
   if(seq!==this.generation)return;
   // Android may also deliver relative companion events with a different yaw origin.
   if(this.reference==='absolute'&&!e.absolute)return;
   const pose=rearCameraPose(e,angle);
   if(!pose){this.pose=null;this.offset=null;this.state('waiting');return}
   if(this.reference!==pose.reference){this.offset=null;this.reference=pose.reference}
   this.pose=pose;this.arm(seq);this.sample(pose);
   if(this.offset===null)this.state('align');else{this.state('tracking');this.apply({...pose,azimuth:wrapDegrees(pose.azimuth+this.offset)})}
  })}catch{this.stop(false);this.state('unavailable')}
 }
 align(azimuth:number,altitude:number){
  if(!this.pose||!Number.isFinite(azimuth)||!Number.isFinite(altitude)||Math.abs(this.pose.altitude)>85||Math.abs(altitude)>85||Math.abs(this.pose.altitude-altitude)>15)return false;
  this.offset=wrapDegrees(azimuth-this.pose.azimuth);this.state('tracking');this.apply({...this.pose,azimuth:wrapDegrees(this.pose.azimuth+this.offset)});return true;
 }
 private arm(seq:number){clearTimeout(this.timer);this.timer=setTimeout(()=>{if(seq===this.generation){this.stop(false);this.state('unavailable')}},this.timeout)}
 stop(report=true){this.generation++;clearTimeout(this.timer);this.off?.();this.off=undefined;this.pose=null;this.offset=null;this.reference=null;if(report)this.state('idle')}
}
