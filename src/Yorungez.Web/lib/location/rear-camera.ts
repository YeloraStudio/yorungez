export interface LocalVideoStream {getTracks():{stop:()=>void}[]}
export function verifiedRearCamera<T extends LocalVideoStream&{getVideoTracks():{getSettings?:()=>{facingMode?:string}}[]}>(stream:T):T{
 let facing:string|undefined;try{facing=stream.getVideoTracks()[0]?.getSettings?.().facingMode}catch{/* Unverifiable cameras are not displayed. */}
 if(facing!=='environment'){stream.getTracks().forEach(t=>t.stop());throw new Error('Rear camera could not be verified')}
 return stream;
}
export type VideoState='idle'|'requesting'|'ready'|'error';
export class RearCameraSession<T extends LocalVideoStream>{
 private generation=0;private stream:T|null=null;
 private acquire:()=>Promise<T>;private show:(stream:T|null)=>void;private state:(s:VideoState)=>void;
 constructor(acquire:()=>Promise<T>,show:(stream:T|null)=>void,state:(s:VideoState)=>void){this.acquire=acquire;this.show=show;this.state=state}
 async start(){this.stop();const seq=++this.generation;this.state('requesting');
  try{const stream=await this.acquire();if(seq!==this.generation){stream.getTracks().forEach(t=>t.stop());return}this.stream=stream;this.show(stream);this.state('ready')}
  catch{if(seq===this.generation)this.state('error')}
 }
 stop(){this.generation++;this.stream?.getTracks().forEach(t=>t.stop());this.stream=null;this.show(null);this.state('idle')}
}
