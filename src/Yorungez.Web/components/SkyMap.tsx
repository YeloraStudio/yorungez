"use client";
import { useEffect, useRef, useState } from "react";
import type { Camera, Language, SkyCatalog } from "../lib/sky/types.ts";
import type { SkyFrame } from "../lib/sky/frame-contract.ts";
import { SOLAR_IDS } from "../lib/sky/frame-contract.ts";
import { equatorialVector, horizontalVector, normalizedCamera, pickObject, projector, projectionScale } from "../lib/sky/projection.ts";
import { createRenderer } from "../lib/sky/renderers.ts";
import { planningText } from "../lib/planning-text.ts";
import { terrainOpacity } from "../lib/sky/terrain.ts";
import { createNaturalScene, screenRay } from "../lib/sky/natural-scene.ts";
import { starAppearance, daylight } from "../lib/sky/appearance.ts";
import { drawConstellationArt } from "../lib/sky/art.ts";
import type { RendererKind } from "../lib/sky/renderers.ts";
import type { Layers } from "../lib/sky/layers.ts";
import type { Texts } from "../lib/i18n.ts";
interface Props {
  catalog: SkyCatalog; frame: SkyFrame | null; camera: Camera; language: Language; text: Texts;
  selected: string | null; layers: Layers;
  tracking?:boolean;cameraOverlay?:boolean;cameraPreview?:boolean;
  onCamera: (camera: Camera) => void; onSelect: (id: string) => void; renderer?: RendererKind;
}
const solarColors=["#fff2c5","#e9edf5","#c3b8a8","#f0d7ad","#e7a28a","#dfc5a5","#ebd3a3","#a0d6de","#9eaedc"];
export function starColor(index:number|null){return index===null?"#e1e9f5":index<0?"#acccff":index<.4?"#d5e4ff":index<.9?"#f1edda":index<1.4?"#ebc999":"#e5ae8b";}
const clamp=(x:number)=>Math.max(0,Math.min(1,x));
function mix(a:number[],b:number[],n:number){return `rgb(${a.map((x,i)=>Math.round(x+(b[i]-x)*n)).join(",")})`;}
export default function SkyMap(props:Props){
  const host=useRef<HTMLDivElement>(null), overlay=useRef<HTMLCanvasElement>(null),background=useRef<HTMLCanvasElement>(null);
  const [simplified,setSimplified]=useState(false),fallback=useRef(false),[exploring,setExploring]=useState(false),exploration=useRef(false);
  const latest=useRef(props);latest.current=props;
  const projected=useRef(new Float32Array(0)),size=useRef({width:1,height:1});
  const requestDraw=useRef<()=>void>(()=>{}),view=useRef(props.camera);
  const drag=useRef<{x:number;y:number;camera:Camera;moved:boolean}|null>(null);
  const fingers=useRef(new Map<number,{x:number;y:number}>()),pinch=useRef<{distance:number;fov:number}|null>(null);
  useEffect(()=>{
    const viewport=host.current!, canvas=overlay.current!,base=background.current!;
    const renderer=createRenderer(props.renderer??"canvas");renderer.element.classList.add("star-surface");viewport.prepend(renderer.element);
    const ctx=canvas.getContext("2d")!,bg=base.getContext("2d")!,catalog=props.catalog;
    const ids=[...catalog.stars.map(s=>s.id),...SOLAR_IDS,...catalog.constellations.map(c=>c.id),...(catalog.deepSky??[]).map(o=>o.id)];
    const indices=new Map(catalog.stars.map((s,i)=>[s.id,i])),images=new Map<string,HTMLImageElement>();
    const natural=createNaturalScene(schedule);viewport.prepend(natural.sky);viewport.append(natural.ground);
    const radii=new Float32Array(catalog.stars.length+9),opacities=new Float32Array(catalog.stars.length+9);
    const colors:string[]=catalog.stars.map((s,i)=>{radii[i]=starAppearance(s.magnitude).radius;return starColor(s.colorIndex)});
    solarColors.forEach((c,i)=>{colors.push(c);radii[catalog.stars.length+i]=i<2?0:3.2});
    let scheduled=0;
    function draw(){
      scheduled=0;if(fallback.current===natural.gpu){fallback.current=!natural.gpu;setSimplified(!natural.gpu)}const p=latest.current,frame=p.frame,{width,height}=size.current,dpr=Math.min(devicePixelRatio||1,2);
      for(const c of [canvas,base]){const w=Math.round(width*dpr),h=Math.round(height*dpr);if(c.width!==w||c.height!==h){c.width=w;c.height=h;}}
      ctx.setTransform(dpr,0,0,dpr,0,0);ctx.clearRect(0,0,width,height);bg.setTransform(dpr,0,0,dpr,0,0);
      const previous=view.current,target=p.camera,reduced=matchMedia("(prefers-reduced-motion: reduce)").matches;
      const da=((target.azimuth-previous.azimuth+540)%360)-180;
      const dr=(((target.roll??0)-(previous.roll??0)+540)%360)-180;
      const moving=Math.abs(da)+Math.abs(dr)+Math.abs(target.altitude-previous.altitude)+Math.abs(target.fieldOfView-previous.fieldOfView)>.015;
      view.current=p.tracking||reduced||!moving?target:{...target,azimuth:previous.azimuth+da*.28,altitude:previous.altitude+(target.altitude-previous.altitude)*.28,roll:(previous.roll??0)+dr*.28,fieldOfView:previous.fieldOfView+(target.fieldOfView-previous.fieldOfView)*.28};
      if(moving&&!reduced&&!p.tracking)schedule();
      const camera=view.current,project=projector(camera,width,height),sunIndex=catalog.stars.length;
      const sunAlt=frame?.angles[sunIndex*2+1]??-30,day=p.layers.atmosphere?daylight(sunAlt):0;
      const sky=bg.createLinearGradient(0,0,0,height);
      sky.addColorStop(0,mix([7,8,11],[43,81,111],day));sky.addColorStop(.7,mix([15,15,19],[110,142,158],day));sky.addColorStop(1,mix([28,25,29],[203,192,171],day));
      if(!natural.gpu){bg.fillStyle=sky;bg.fillRect(0,0,width,height)}else bg.clearRect(0,0,width,height);
      if(!frame)return;
      const selectedIndex=p.selected?ids.indexOf(p.selected):-1,selectedHidden=selectedIndex>=0&&natural.occludes(frame.angles[selectedIndex*2],frame.angles[selectedIndex*2+1]);
      const groundOpacity=terrainOpacity(camera.altitude,selectedHidden);const reveal=p.layers.landscape&&groundOpacity<.5;if(exploration.current!==reveal){exploration.current=reveal;setExploring(reveal)}viewport.dataset.groundOpacity=groundOpacity.toFixed(3);viewport.dataset.fieldOfView=camera.fieldOfView.toFixed(1);viewport.dataset.cameraAltitude=camera.altitude.toFixed(1);viewport.dataset.cameraRoll=(camera.roll??0).toFixed(1);viewport.dataset.cameraAzimuth=camera.azimuth.toFixed(1);
      natural.draw(camera,width,height,dpr,[frame.vectors[sunIndex*3],frame.vectors[sunIndex*3+1],frame.vectors[sunIndex*3+2]],sunAlt,p.layers.atmosphere,p.layers.landscape,groundOpacity);
      if(projected.current.length!==ids.length*2)projected.current=new Float32Array(ids.length*2);
      projected.current.fill(NaN);
      if(frame.canPublishAzimuth)for(let i=0;i<ids.length;i++){
        if(p.cameraOverlay&&frame.angles[i*2+1]<0)continue;
        if((i>=catalog.stars.length+9&&i<catalog.stars.length+9+catalog.constellations.length&&!p.layers.constellations)||(i>=catalog.stars.length+9+catalog.constellations.length&&!p.layers.deepSky))continue;
        if(i<opacities.length)opacities[i]=frame.angles[i*2+1]<0?1:1-day*.999;
        if(p.layers.landscape&&groundOpacity>.95&&ids[i]!==p.selected&&natural.occludes(frame.angles[i*2],frame.angles[i*2+1]))continue;
        if(i>=catalog.stars.length+9+catalog.constellations.length&&day>.35&&frame.angles[i*2+1]>=0&&ids[i]!==p.selected)continue;
        const point=project(frame.vectors[i*3],frame.vectors[i*3+1],frame.vectors[i*3+2]);
        if(point){projected.current[i*2]=point[0];projected.current[i*2+1]=point[1];}
      }
      renderer.element.style.opacity="1";
      if(p.layers.art&&!p.cameraOverlay&&frame.canPublishAzimuth)drawConstellationArt(bg,catalog,frame.artVectors,project,images,schedule);
      renderer.draw({points:projected.current,radii,colors,opacities,count:radii.length,width,height,dpr});
      function curve(points:[number,number,number][],color:string,lineWidth=1){ctx.beginPath();let active=false,prior:[number,number]|null=null;
        for(const vector of points){const point=p.cameraOverlay&&vector[2]<0?null:project(...vector);if(!point||(prior&&Math.hypot(point[0]-prior[0],point[1]-prior[1])>Math.max(width,height)/2)){active=false;prior=point;continue;}if(active)ctx.lineTo(...point);else ctx.moveTo(...point);active=true;prior=point;}
        ctx.strokeStyle=color;ctx.lineWidth=lineWidth;ctx.stroke();}
      if(p.layers.azimuthalGrid){
        for(const alt of [-60,-30,30,60])curve(Array.from({length:181},(_,i)=>horizontalVector(i*2,alt)),"rgba(213,201,203,.24)");
        for(let az=0;az<360;az+=30)curve(Array.from({length:91},(_,i)=>horizontalVector(az,-90+i*2)),"rgba(213,201,203,.24)");
      }
      if(p.layers.equatorialGrid&&frame.canPublishAzimuth){
        for(const dec of [-60,-30,0,30,60])curve(Array.from({length:181},(_,i)=>equatorialVector(frame.equatorialToEnu,i*24/180,dec)),"rgba(195,142,155,.4)");
        for(let ra=0;ra<24;ra+=2)curve(Array.from({length:91},(_,i)=>equatorialVector(frame.equatorialToEnu,ra,-90+i*2)),"rgba(195,142,155,.32)");
      }
      if(p.layers.constellations&&frame.canPublishAzimuth)for(const pattern of catalog.constellations)for(const line of pattern.lines)for(let j=1;j<line.length;j++){
        const a=indices.get(line[j-1])!,b=indices.get(line[j])!,v=frame.vectors;
        const va=[v[a*3],v[a*3+1],v[a*3+2]],vb=[v[b*3],v[b*3+1],v[b*3+2]];
        const angle=Math.acos(Math.max(-1,Math.min(1,va.reduce((s,n,k)=>s+n*vb[k],0))));if(angle<1e-8||angle>Math.PI-.01)continue;
        const steps=Math.max(1,Math.ceil(angle*180/Math.PI/3));
        curve(Array.from({length:steps+1},(_,i)=>{const t=i/steps;return va.map((n,k)=>(n*Math.sin((1-t)*angle)+vb[k]*Math.sin(t*angle))/Math.sin(angle)) as [number,number,number]}),pattern.id===p.selected?"rgba(226,175,184,.9)":"rgba(211,194,196,.34)");
      }
      // Sun and Moon markers stay independent of the day-star extinction preview.
      for(let i=0;i<2;i++){
        const k=sunIndex+i,x=projected.current[k*2],y=projected.current[k*2+1];if(!Number.isFinite(x))continue;
        const angularRadius=i===0?.2666/Math.max(.9,frame.solarEquatorial[2]):.26;
        const radius=Math.max(1.3,2*projectionScale(camera,width,height)*Math.tan(angularRadius*Math.PI/360));
        if(i===0&&p.layers.atmosphere){const extent=radius*5+8,glow=ctx.createRadialGradient(x,y,radius,x,y,extent);glow.addColorStop(0,"rgba(255,249,229,.3)");glow.addColorStop(.25,"rgba(255,245,218,.09)");glow.addColorStop(1,"rgba(255,245,218,0)");ctx.fillStyle=glow;ctx.fillRect(x-extent,y-extent,extent*2,extent*2);}
        ctx.beginPath();ctx.arc(x,y,radius,0,Math.PI*2);ctx.fillStyle=i===0?"#fffdf5":"#e8e6de";ctx.fill();
      }
      const boxes:[number,number,number,number][]=[];ctx.font="11px system-ui";ctx.textAlign="center";
      function label(i:number,text:string,color:string){const x=projected.current[i*2],y=projected.current[i*2+1];if(!Number.isFinite(x)||x<20||x>width-20||y<20||y>height-30)return;
        const l=ctx.measureText(text).width+10,b:[number,number,number,number]=[x-l/2,y+7,x+l/2,y+23];if(boxes.some(q=>b[0]<q[2]&&b[2]>q[0]&&b[1]<q[3]&&b[3]>q[1]))return;boxes.push(b);ctx.fillStyle=color;ctx.fillText(text,x,y+21);}
      if(frame.canPublishAzimuth){
        for(let i=0;i<9;i++)if(day<.75||frame.angles[(sunIndex+i)*2+1]<0||SOLAR_IDS[i]===p.selected||i===0)label(sunIndex+i,p.text.celestialNames[SOLAR_IDS[i]],"#f0e5d1");
        if(day<.2)for(let i=0;i<32;i++)label(i,catalog.stars[i].name,"#c9c5c5");
        if(p.layers.constellations)catalog.constellations.forEach((c,i)=>label(sunIndex+9+i,c.names[p.language],"#c7aeb4"));
        if(p.layers.deepSky)catalog.deepSky?.forEach((o,i)=>{const index=sunIndex+9+catalog.constellations.length+i,x=projected.current[index*2],y=projected.current[index*2+1];if(!Number.isFinite(x))return;ctx.beginPath();ctx.ellipse(x,y,7,4,-.5,0,Math.PI*2);ctx.strokeStyle="rgba(206,164,178,.75)";ctx.stroke();label(index,o.name,"#d7aab6");});
      }
      // CPU fallback uses the same inverse projection at every tilt, including zenith/nadir.
      if(p.layers.landscape&&!natural.gpu){
        ctx.save();ctx.globalAlpha=groundOpacity;ctx.fillStyle=mix([9,10,9],[64,67,48],day);
        const step=8;
        for(let y=0;y<height;y+=step){let start=-1;for(let x=0;x<=width+step;x+=step){
          const below=x<width&&screenRay(camera,width,height,x+step/2,y+step/2)[2]<0;
          if(below&&start<0)start=x;
          if(!below&&start>=0){ctx.fillRect(start,y,x-start,step);start=-1;}
        }}
        ctx.restore();
      }
      curve(Array.from({length:181},(_,i)=>horizontalVector(i*2,0)),"rgba(204,191,184,.25)");
      ctx.font="600 12px system-ui";for(const [az,label] of [[0,p.text.north],[90,p.text.east],[180,p.text.south],[270,p.text.west]] as const){const point=project(...horizontalVector(az,0));if(point){ctx.fillStyle="#e3d9d4";ctx.fillText(label,point[0],point[1]-8);}}
      if(p.selected){const index=ids.indexOf(p.selected),x=projected.current[index*2],y=projected.current[index*2+1];if(Number.isFinite(x)){ctx.beginPath();ctx.arc(x,y,16,0,Math.PI*2);ctx.strokeStyle="#e9b6bf";ctx.lineWidth=1;ctx.stroke();}}
    }
    function schedule(){if(!scheduled)scheduled=requestAnimationFrame(draw)}requestDraw.current=schedule;
    const resize=new ResizeObserver(entries=>{size.current={width:entries[0].contentRect.width,height:entries[0].contentRect.height};schedule()});resize.observe(viewport);
    const wheel=(event:WheelEvent)=>{event.preventDefault();const p=latest.current;const delta=event.deltaY*(event.deltaMode===1?16:event.deltaMode===2?size.current.height:1);p.onCamera(normalizedCamera({...p.camera,fieldOfView:p.camera.fieldOfView*Math.exp(Math.max(-160,Math.min(160,delta))*.002)}))};
    viewport.addEventListener("wheel",wheel,{passive:false});schedule();
    return()=>{resize.disconnect();viewport.removeEventListener("wheel",wheel);cancelAnimationFrame(scheduled);renderer.dispose();natural.dispose();for(const image of images.values())image.onload=null;};
  },[props.catalog,props.renderer]);
  useEffect(()=>{requestDraw.current()},[props.frame,props.camera,props.language,props.selected,props.layers,props.tracking,props.cameraOverlay]);
  return <div ref={host} className={`sky-viewport${props.cameraOverlay?' camera-overlay':''}${props.cameraPreview?' camera-preview':''}`} role="region" tabIndex={0} aria-label={props.text.mapLabel} aria-describedby="map-help"
    onKeyDown={event => {
      const c = props.camera; let next = c;
      if (event.key === "ArrowLeft") next = { ...c, azimuth: c.azimuth - 5 };
      else if (event.key === "ArrowRight") next = { ...c, azimuth: c.azimuth + 5 };
      else if (event.key === "ArrowUp") next = { ...c, altitude: c.altitude + 5 };
      else if (event.key === "ArrowDown") next = { ...c, altitude: c.altitude - 5 };
      else if (event.key === "+" || event.key === "=") next = { ...c, fieldOfView: c.fieldOfView / 1.15 };
      else if (event.key === "-") next = { ...c, fieldOfView: c.fieldOfView * 1.15 };
      else return;
      event.preventDefault(); props.onCamera(normalizedCamera(next));
    }}
    onDoubleClick={() => props.onCamera(normalizedCamera({ ...props.camera, fieldOfView: props.camera.fieldOfView / 1.6 }))}
    onPointerDown={event => {
      if (event.button !== 0) return;
      event.currentTarget.setPointerCapture(event.pointerId);
      fingers.current.set(event.pointerId, { x: event.clientX, y: event.clientY });
      drag.current = { x: event.clientX, y: event.clientY, camera: props.camera, moved: false };
      if (fingers.current.size === 2) { const [a, b] = [...fingers.current.values()]; pinch.current = { distance: Math.hypot(a.x-b.x, a.y-b.y), fov: props.camera.fieldOfView }; }
    }}
    onPointerMove={event => {
      if (!fingers.current.has(event.pointerId)) return;
      fingers.current.set(event.pointerId, { x: event.clientX, y: event.clientY });
      if (fingers.current.size === 2 && pinch.current) {
        const [a, b] = [...fingers.current.values()];
        if (drag.current) drag.current.moved = true;
        props.onCamera(normalizedCamera({ ...props.camera, fieldOfView: pinch.current.fov * pinch.current.distance / Math.max(1, Math.hypot(a.x-b.x, a.y-b.y)) })); return;
      }
      if (!drag.current) return;
      const dx = event.clientX - drag.current.x, dy = event.clientY - drag.current.y;
      if (Math.hypot(dx, dy) > 4) drag.current.moved = true;
      const degrees = drag.current.camera.fieldOfView / Math.max(size.current.width, size.current.height);
      props.onCamera(normalizedCamera({ ...drag.current.camera, azimuth: drag.current.camera.azimuth - dx * degrees, altitude: drag.current.camera.altitude + dy * degrees }));
    }}
    onPointerUp={event => {
      if (drag.current && !drag.current.moved && props.frame?.canPublishAzimuth && fingers.current.size === 1) {
        const rect = event.currentTarget.getBoundingClientRect();
        const ids = [...props.catalog.stars.map(s => s.id), ...SOLAR_IDS, ...props.catalog.constellations.map(c => c.id), ...(props.catalog.deepSky ?? []).map(o => o.id)];
        const id = pickObject(projected.current, ids, event.clientX - rect.left, event.clientY - rect.top);
        if (id) props.onSelect(id);
      }
      fingers.current.delete(event.pointerId); drag.current = null; pinch.current = null;
    }} onPointerCancel={() => { fingers.current.clear(); drag.current = null; pinch.current = null; }}>
      <canvas ref={background} className="sky-background" aria-hidden="true" />
      <canvas ref={overlay} className="sky-overlay" aria-hidden="true" />
      {exploring&&<p className="terrain-notice glass" role="status">{planningText[props.language].belowExplore}</p>}
      {simplified&&<p className="render-fallback glass" role="status">{props.language==="tr"?"Bu cihazda sade harita görünümü kullanılıyor. Fotoğraf panorama gösterilemiyor.":"This device is using the simplified map. The photographic panorama is unavailable."}</p>}
  </div>;
}
