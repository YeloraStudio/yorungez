import type {SkyFrame} from './frame-contract.ts';
import type {SkyCatalog} from './types.ts';
const radians=Math.PI/180;
/** Small stereographic field from the already computed horizontal frame; no new ephemeris calculation. */
export function finderField(catalog:SkyCatalog,frame:SkyFrame|null,index:number,fieldOfView=20){
 if(!frame?.canPublishAzimuth||index<0||index*2+1>=frame.angles.length)return null;
 const az=frame.angles[index*2]*radians,alt=frame.angles[index*2+1]*radians;
 if(!Number.isFinite(az)||!Number.isFinite(alt))return null;
 const center=[Math.cos(alt)*Math.sin(az),Math.sin(alt),Math.cos(alt)*Math.cos(az)],right=[Math.cos(az),0,-Math.sin(az)],up=[-Math.sin(alt)*Math.sin(az),Math.cos(alt),-Math.sin(alt)*Math.cos(az)];
 const dot=(a:number[],b:number[])=>a.reduce((sum,n,i)=>sum+n*b[i],0),radius=2*Math.tan(fieldOfView*radians/4);
 const points=[];
 for(let i=0;i<catalog.stars.length;i++){
  if(catalog.stars[i].magnitude>6.5)continue;
  const a=frame.angles[i*2]*radians,h=frame.angles[i*2+1]*radians;
  const v=[Math.cos(h)*Math.sin(a),Math.sin(h),Math.cos(h)*Math.cos(a)],denominator=1+dot(center,v);
  if(denominator<=0)continue;
  const x=dot(right,v)*2/denominator/radius,y=-dot(up,v)*2/denominator/radius;
  if(Number.isFinite(x)&&Number.isFinite(y)&&Math.abs(x)<1&&Math.abs(y)<.58)points.push({id:catalog.stars[i].id,x:180+x*180,y:105+y*180,magnitude:catalog.stars[i].magnitude});
 }
 return {points:points.sort((a,b)=>a.magnitude-b.magnitude).slice(0,160),fieldOfView};
}
