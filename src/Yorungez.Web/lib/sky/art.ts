import type { Camera, SkyCatalog } from "./types.ts";
import { horizontalVector, projectionScale } from "./projection.ts";
type Point = [number,number];
type Vector = [number,number,number];
const dot = (a:Vector,b:Vector) => a[0]*b[0]+a[1]*b[1]+a[2]*b[2];
const fadeMs=180,artOpacity=.34;
type Affine=[number,number,number,number,number,number];
export type ArtMesh={image:HTMLImageElement;vertices:number[];opacity:number;affine?:Affine};

function motionAffine(outline:Point[]):Affine|undefined{
  const [a,b,c,d]=outline;
  const dx=d[0]-b[0]-c[0]+a[0],dy=d[1]-b[1]-c[1]+a[1];
  // Use a single draw when its four corners deviate by at most three pixels.
  if(Math.hypot(dx,dy)>12)return;
  return [b[0]-a[0]+dx/2,b[1]-a[1]+dy/2,c[0]-a[0]+dx/2,c[1]-a[1]+dy/2,a[0]-dx/4,a[1]-dy/4];
}

function visibleFraction(outline:Point[],width:number,height:number){
  if(outline.length<4)return 1;
  const xs=outline.map(point=>point[0]),ys=outline.map(point=>point[1]);
  const left=Math.min(...xs),right=Math.max(...xs),top=Math.min(...ys),bottom=Math.max(...ys);
  const overlapX=Math.min(width,right)-Math.max(0,left);
  const overlapY=Math.min(height,bottom)-Math.max(0,top);
  // Reach full opacity once a small part of the figure is inside the view.
  const edgeX=Math.max(1,Math.min(56,(right-left)*.4));
  const edgeY=Math.max(1,Math.min(56,(bottom-top)*.4));
  return Math.max(0,Math.min(1,overlapX/edgeX,overlapY/edgeY));
}

export function triangleInViewport(a:Point,b:Point,c:Point,width:number,height:number) {
  if(Math.max(a[0],b[0],c[0])<=0 || Math.min(a[0],b[0],c[0])>=width ||
     Math.max(a[1],b[1],c[1])<=0 || Math.min(a[1],b[1],c[1])>=height) return false;
  const orientation=Math.sign((b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0]));
  function crossesEdge(start:Point,end:Point) {
    const x=-(end[1]-start[1])*orientation,y=(end[0]-start[0])*orientation;
    return x*((x>0?width:0)-start[0])+y*((y>0?height:0)-start[1])>0;
  }
  return orientation!==0 && crossesEdge(a,b) && crossesEdge(b,c) && crossesEdge(c,a);
}

// Three catalogue star anchors define a linear texture-to-sphere basis. A mesh
// then projects normalized 3D directions, avoiding a flat screen-space sticker.
export function projectConstellationArt(catalog:SkyCatalog,vectors:Float64Array,
  project:(...ray:Vector)=>Point|null,camera:Camera,
  view:{width:number;height:number;now:number;moving:boolean;reduced:boolean},
  images:Map<string,HTMLImageElement>,entered:Map<string,number>,schedule:()=>void) {
  const {width,height,now,moving,reduced}=view;
  const meshes:ArtMesh[]=[];
  let animating=false;
  const art=catalog.art;if(!art)return {meshes,animating};
  const leaving=new Set(entered.keys());
  const forward=horizontalVector(camera.azimuth,camera.altitude);
  const radius=Math.hypot(width,height)/2,scale=projectionScale(camera,width,height);
  const viewRadius=camera.projection==='perspective'?Math.atan(radius/scale):2*Math.atan(radius/(2*scale));
  for (const figure of art.figures) {
    const [a,b,c] = figure.anchors.map(i => art.anchors[i]);
    const det = (b.x-a.x)*(c.y-a.y)-(c.x-a.x)*(b.y-a.y); if (Math.abs(det)<1) continue;
    const [ia,ib,ic]=figure.anchors.map(index=>index*3);
    function direction(x:number,y:number):Vector {
      const u=((x-a.x)*(c.y-a.y)-(y-a.y)*(c.x-a.x))/det;
      const v=((b.x-a.x)*(y-a.y)-(b.y-a.y)*(x-a.x))/det;
      const w=1-u-v;
      const rx=w*vectors[ia]+u*vectors[ib]+v*vectors[ic];
      const ry=w*vectors[ia+1]+u*vectors[ib+1]+v*vectors[ic+1];
      const rz=w*vectors[ia+2]+u*vectors[ib+2]+v*vectors[ic+2];
      const length=Math.hypot(rx,ry,rz);
      return [rx/length,ry/length,rz/length];
    }
    const [w,h]=figure.size,centre=direction(w/2,h/2);
    const corners=[direction(0,0),direction(w,0),direction(0,h),direction(w,h)];
    const nearestCorner=Math.min(...corners.map(corner=>dot(centre,corner)));
    // The texture rectangle lies in the cone formed by its corner rays if
    // all four corners are in the centre's hemisphere.
    if(nearestCorner>0){
      const reach=viewRadius+Math.acos(Math.min(1,nearestCorner));
      if(reach<Math.PI && dot(centre,forward)<Math.cos(reach)) continue;
    }
    let image=images.get(figure.src);
    if(image && (!image.complete || !image.naturalWidth)) continue;
    const outline=corners.map(corner=>project(...corner)).filter((point):point is Point=>point!==null);
    const xs=outline.map(point=>point[0]),ys=outline.map(point=>point[1]);
    const extent=Math.max(Math.max(...xs)-Math.min(...xs),Math.max(...ys)-Math.min(...ys));
    // Retain a finer mesh at rest. While panning, already-loaded figures
    // use fewer tiles, then sharpen on the final camera frame.
    const coarse=moving&&image;
    const steps=outline.length<4?(coarse?4:8):coarse
      ?Math.max(1,Math.min(4,Math.ceil(extent/420)))
      :Math.max(2,Math.min(8,Math.ceil(extent/110)));
    const stride=steps+1,dx=w/steps,dy=h/steps;
    const projected=Array.from({length:stride*stride},(_,i)=>project(...direction((i%stride)*dx,Math.floor(i/stride)*dy)));
    const vertices:number[]=[];
    mesh: for(let y=0;y<steps;y++)for(let x=0;x<steps;x++){
      const i=y*stride+x,p0=projected[i],p1=projected[i+1],p2=projected[i+stride+1],p3=projected[i+stride];
      if(!p0||!p2)continue;
      const first=p1&&triangleInViewport(p0,p1,p2,width,height),second=p3&&triangleInViewport(p0,p2,p3,width,height);
      if(!first&&!second)continue;
      if(!image){
        image=new Image();image.decoding='async';image.onload=schedule;
        images.set(figure.src,image);image.src=figure.src;
        break mesh;
      }
      const u0=x/steps,v0=y/steps,u1=(x+1)/steps,v1=(y+1)/steps;
      if(first&&p1)vertices.push(...p0,u0,v0,...p1,u1,v0,...p2,u1,v1);
      if(second&&p3)vertices.push(...p0,u0,v0,...p2,u1,v1,...p3,u0,v1);
    }
    if(!image||!vertices.length)continue;
    const start=entered.get(figure.id)??now;
    entered.set(figure.id,start);
    leaving.delete(figure.id);
    const elapsed=reduced?1:Math.min(1,(now-start)/fadeMs);
    animating ||= elapsed<1;
    const edge=visibleFraction(projected.filter((point):point is Point=>point!==null),width,height);
    const opacity=artOpacity*(reduced?1:edge*(1-(1-elapsed)**2));
    if(opacity>0)meshes.push({image,vertices,opacity,
      affine:moving&&outline.length===4&&extent<=420?motionAffine(outline):undefined});
  }
  for(const id of leaving)entered.delete(id);
  return {meshes,animating};
}

// Preserve the mesh on devices where the WebGL art pass is unavailable.
export function drawCanvasArt(ctx:CanvasRenderingContext2D,meshes:ArtMesh[]){
  ctx.save();
  for(const {image,vertices:v,opacity,affine} of meshes){
    ctx.globalAlpha=opacity;
    if(affine){
      ctx.save();ctx.transform(...affine);ctx.drawImage(image,0,0,1,1);ctx.restore();
      continue;
    }
    for(let i=0;i<v.length;i+=12){
      const x=v[i],y=v[i+1],u=v[i+2],t=v[i+3];
      const bx=v[i+4]-x,by=v[i+5]-y,bu=v[i+6]-u,bt=v[i+7]-t;
      const cx=v[i+8]-x,cy=v[i+9]-y,cu=v[i+10]-u,ct=v[i+11]-t;
      const det=bu*ct-cu*bt;
      const a=(bx*ct-cx*bt)/det,b=(by*ct-cy*bt)/det;
      const c=(bu*cx-cu*bx)/det,d=(bu*cy-cu*by)/det;
      ctx.save();ctx.beginPath();ctx.moveTo(x,y);ctx.lineTo(v[i+4],v[i+5]);ctx.lineTo(v[i+8],v[i+9]);ctx.closePath();ctx.clip();
      ctx.transform(a,b,c,d,x-a*u-c*t,y-b*u-d*t);
      const du=Math.max(bu,cu),dt=Math.max(bt,ct);
      ctx.drawImage(image,u*image.naturalWidth,t*image.naturalHeight,du*image.naturalWidth,dt*image.naturalHeight,u,t,du,dt);
      ctx.restore();
    }
  }
  ctx.restore();
}
