"use client";
import {useEffect,useRef} from 'react';
export default function RearCameraView({stream,onEnded}:{stream:MediaStream;onEnded:()=>void}){
 const video=useRef<HTMLVideoElement>(null),latest=useRef(onEnded);latest.current=onEnded;
 useEffect(()=>{const element=video.current!;element.srcObject=stream;const ended=()=>latest.current();
  const tracks=stream.getVideoTracks();tracks.forEach(t=>t.addEventListener('ended',ended));
  void element.play().catch(ended);return()=>{tracks.forEach(t=>t.removeEventListener('ended',ended));element.pause();element.srcObject=null};
 },[stream]);
 return <video ref={video} className="rear-camera-view" autoPlay muted playsInline aria-hidden="true"/>;
}
