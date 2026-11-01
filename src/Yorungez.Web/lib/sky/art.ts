import type { SkyCatalog } from "./types.ts";
type Point = [number,number];
// Three catalogue star anchors define a linear texture-to-sphere basis. A mesh
// then projects normalized 3D directions, avoiding a flat screen-space sticker.
export function drawConstellationArt(ctx: CanvasRenderingContext2D, catalog: SkyCatalog, vectors: Float64Array,
  project: (x:number,y:number,z:number)=>Point|null, images: Map<string,HTMLImageElement>, schedule:()=>void) {
  if (!catalog.art) return;
  for (const figure of catalog.art.figures) {
    const anchors = figure.anchors.map(i => catalog.art!.anchors[i]);
    const [a,b,c] = anchors;
    const det = (b.x-a.x)*(c.y-a.y)-(c.x-a.x)*(b.y-a.y); if (Math.abs(det)<1) continue;
    function point(x:number,y:number) {
      const u=((x-a.x)*(c.y-a.y)-(y-a.y)*(c.x-a.x))/det;
      const v=((b.x-a.x)*(y-a.y)-(b.y-a.y)*(x-a.x))/det;
      const ray = [0,0,0];
      for(let k=0;k<3;k++) ray[k]=(1-u-v)*vectors[figure.anchors[0]*3+k]+u*vectors[figure.anchors[1]*3+k]+v*vectors[figure.anchors[2]*3+k];
      const length=Math.hypot(...ray); return project(ray[0]/length,ray[1]/length,ray[2]/length);
    }
    const centre=point(figure.size[0]/2,figure.size[1]/2);
    if (!centre || centre[0]<-ctx.canvas.width || centre[0]>ctx.canvas.width*2 || centre[1]<-ctx.canvas.height || centre[1]>ctx.canvas.height*2) continue;
    let image=images.get(figure.src);
    if(!image){image=new Image();image.onload=schedule;image.src=figure.src;images.set(figure.src,image);}
    if(!image.complete || !image.naturalWidth) continue;
    const steps=8, dx=figure.size[0]/steps, dy=figure.size[1]/steps;
    function triangle(source:Point[],target:(Point|null)[]) {
      if(target.some(p=>!p))return;
      const [s0,s1,s2]=source, [p0,p1,p2]=target as Point[];
      if(Math.max(Math.hypot(p1[0]-p0[0],p1[1]-p0[1]),Math.hypot(p2[0]-p0[0],p2[1]-p0[1]))>ctx.canvas.width)return;
      const den=(s1[0]-s0[0])*(s2[1]-s0[1])-(s2[0]-s0[0])*(s1[1]-s0[1]);
      const aa=((p1[0]-p0[0])*(s2[1]-s0[1])-(p2[0]-p0[0])*(s1[1]-s0[1]))/den;
      const bb=((p1[1]-p0[1])*(s2[1]-s0[1])-(p2[1]-p0[1])*(s1[1]-s0[1]))/den;
      const cc=((s1[0]-s0[0])*(p2[0]-p0[0])-(s2[0]-s0[0])*(p1[0]-p0[0]))/den;
      const dd=((s1[0]-s0[0])*(p2[1]-p0[1])-(s2[0]-s0[0])*(p1[1]-p0[1]))/den;
      ctx.save();ctx.beginPath();ctx.moveTo(...p0);ctx.lineTo(...p1);ctx.lineTo(...p2);ctx.closePath();ctx.clip();
      ctx.transform(aa,bb,cc,dd,p0[0]-aa*s0[0]-cc*s0[1],p0[1]-bb*s0[0]-dd*s0[1]);ctx.drawImage(image!,0,0,figure.size[0],figure.size[1]);ctx.restore();
    }
    ctx.save();ctx.globalAlpha=.34;
    for(let y=0;y<steps;y++)for(let x=0;x<steps;x++){
      const p:Point[]=[[x*dx,y*dy],[(x+1)*dx,y*dy],[(x+1)*dx,(y+1)*dy],[x*dx,(y+1)*dy]];
      const q=p.map(v=>point(...v));triangle([p[0],p[1],p[2]],[q[0],q[1],q[2]]);triangle([p[0],p[2],p[3]],[q[0],q[2],q[3]]);
    }
    ctx.restore();
  }
}
