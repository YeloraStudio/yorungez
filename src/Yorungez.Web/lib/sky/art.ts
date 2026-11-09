import type { Camera, SkyCatalog } from "./types.ts";
import { horizontalVector, projectionScale } from "./projection.ts";
type Point = [number,number];
type Vector = [number,number,number];
const dot = (a:Vector,b:Vector) => a[0]*b[0]+a[1]*b[1]+a[2]*b[2];

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
export function drawConstellationArt(ctx: CanvasRenderingContext2D, catalog: SkyCatalog, vectors: Float64Array,
  project: (x:number,y:number,z:number)=>Point|null, camera:Camera,width:number,height:number,
  images: Map<string,HTMLImageElement>, schedule:()=>void,moving=false) {
  const art=catalog.art;if(!art) return;
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
    function triangle(s0:Point,s1:Point,s2:Point,p0:Point,p1:Point,p2:Point,texture:HTMLImageElement,x:number,y:number) {
      const den=(s1[0]-s0[0])*(s2[1]-s0[1])-(s2[0]-s0[0])*(s1[1]-s0[1]);
      const aa=((p1[0]-p0[0])*(s2[1]-s0[1])-(p2[0]-p0[0])*(s1[1]-s0[1]))/den;
      const bb=((p1[1]-p0[1])*(s2[1]-s0[1])-(p2[1]-p0[1])*(s1[1]-s0[1]))/den;
      const cc=((s1[0]-s0[0])*(p2[0]-p0[0])-(s2[0]-s0[0])*(p1[0]-p0[0]))/den;
      const dd=((s1[0]-s0[0])*(p2[1]-p0[1])-(s2[0]-s0[0])*(p1[1]-p0[1]))/den;
      ctx.save();ctx.beginPath();ctx.moveTo(...p0);ctx.lineTo(...p1);ctx.lineTo(...p2);ctx.closePath();ctx.clip();
      ctx.transform(aa,bb,cc,dd,p0[0]-aa*s0[0]-cc*s0[1],p0[1]-bb*s0[0]-dd*s0[1]);
      // Limit each clipped draw to its source tile. Drawing the whole texture
      // repeatedly creates large intermediate surfaces on software canvases.
      const sx=texture.naturalWidth/w,sy=texture.naturalHeight/h;
      ctx.drawImage(texture,x*sx,y*sy,dx*sx,dy*sy,x,y,dx,dy);
      ctx.restore();
    }
    ctx.save();ctx.globalAlpha=.34;
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
      const x0=x*dx,y0=y*dy,x1=x0+dx,y1=y0+dy;
      if(first&&p1)triangle([x0,y0],[x1,y0],[x1,y1],p0,p1,p2,image,x0,y0);
      if(second&&p3)triangle([x0,y0],[x1,y1],[x0,y1],p0,p2,p3,image,x0,y0);
    }
    ctx.restore();
  }
}
