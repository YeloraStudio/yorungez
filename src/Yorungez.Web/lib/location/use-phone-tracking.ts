"use client";
import {useEffect,useRef,useState} from 'react';
import {PointingSession,type PhonePose,type PointingState} from './pointing.ts';
import {RearCameraSession,verifiedRearCamera,type VideoState} from './rear-camera.ts';
import type {OrientationSample} from './compass.ts';
export function usePhoneTracking(contextKey:string|null,onPose:(p:PhonePose)=>void,onStop:()=>void){
 const [state,setState]=useState<PointingState>('idle'),[sample,setSample]=useState<PhonePose|null>(null),[alignmentError,setAlignmentError]=useState(false);
 const [stream,setStream]=useState<MediaStream|null>(null),[videoState,setVideoState]=useState<VideoState>('idle');
 const session=useRef<PointingSession|null>(null),video=useRef<RearCameraSession<MediaStream>|null>(null),latest=useRef({onPose,onStop,contextKey});latest.current={onPose,onStop,contextKey};
 useEffect(()=>{
  let previousState:PointingState='idle',lastSample=0,lastApply=0;
  type OrientationConstructor=typeof DeviceOrientationEvent&{requestPermission?:(absolute?:boolean)=>Promise<string>};
  const constructor=window.DeviceOrientationEvent as OrientationConstructor|undefined;
  const cameraSession=new RearCameraSession<MediaStream>(()=>{
   if(!window.isSecureContext||!navigator.mediaDevices?.getUserMedia)return Promise.reject(new Error('Camera unavailable'));
   return navigator.mediaDevices.getUserMedia({audio:false,video:{facingMode:{exact:'environment'},width:{ideal:1280},height:{ideal:720}}}).then(verifiedRearCamera);
  },setStream,setVideoState);video.current=cameraSession;
  const runner=new PointingSession({secure:window.isSecureContext,supported:!!constructor,
   requestPermission:constructor?.requestPermission?()=>constructor.requestPermission!(true):undefined,
   subscribe:cb=>{
    const read=(event:Event)=>cb(event as unknown as OrientationSample,screen.orientation?.angle??(window as Window&{orientation?:number}).orientation??0);
    window.addEventListener('deviceorientationabsolute',read);window.addEventListener('deviceorientation',read);
    return()=>{window.removeEventListener('deviceorientationabsolute',read);window.removeEventListener('deviceorientation',read)};
   }},next=>{
    setState(next);if(next!==previousState){lastSample=lastApply=0;if(next!=='tracking'){cameraSession.stop();latest.current.onStop()}}previousState=next;
    if(['idle','denied','unsupported','insecure','unavailable','waiting'].includes(next))setSample(null);
   },pose=>{const now=performance.now();if(!lastSample||now-lastSample>=180){lastSample=now;setSample(pose)}},pose=>{
    if(!latest.current.contextKey){runner.stop();return}const now=performance.now();if(!lastApply||now-lastApply>=32){lastApply=now;latest.current.onPose(pose)}
   });session.current=runner;
  const pause=()=>{runner.stop();cameraSession.stop();setAlignmentError(false)};
  const hidden=()=>{if(document.hidden)pause()};document.addEventListener('visibilitychange',hidden);window.addEventListener('pagehide',pause);
  return()=>{runner.stop(false);cameraSession.stop();session.current=null;video.current=null;document.removeEventListener('visibilitychange',hidden);window.removeEventListener('pagehide',pause)};
 },[]);
 useEffect(()=>{session.current?.stop();video.current?.stop();setAlignmentError(false)},[contextKey]);
 function start(){if(!latest.current.contextKey)return;setAlignmentError(false);void session.current?.start()}
 function stop(){session.current?.stop();video.current?.stop();setAlignmentError(false)}
 function align(azimuth:number,altitude:number){const ok=session.current?.align(azimuth,altitude)??false;setAlignmentError(!ok);return ok}
 function startCamera(){if(state==='tracking'&&latest.current.contextKey)void video.current?.start()}
 function stopCamera(){video.current?.stop()}
 return {state,sample,start,stop,align,alignmentError,contextReady:!!contextKey,stream,videoState,startCamera,stopCamera};
}
export type PhoneTracking=ReturnType<typeof usePhoneTracking>;
