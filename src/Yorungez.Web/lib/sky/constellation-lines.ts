import type { ConstellationRecord } from './types.ts';

type Vector = [number,number,number];
type Point = [number,number];
type Pattern = { id:string; arcs:Vector[][] };

export function constellationArcs(patterns:ConstellationRecord[],indices:Map<string,number>,vectors:Float64Array):Pattern[]{
  const vector=(index:number):Vector=>[vectors[index*3],vectors[index*3+1],vectors[index*3+2]];
  return patterns.map(pattern=>{
    const arcs:Vector[][]=[];
    for(const line of pattern.lines)for(let i=1;i<line.length;i++){
      const a=indices.get(line[i-1]),b=indices.get(line[i]);
      if(a===undefined||b===undefined)continue;
      const start=vector(a),end=vector(b);
      const angle=Math.acos(Math.max(-1,Math.min(1,start[0]*end[0]+start[1]*end[1]+start[2]*end[2])));
      if(angle<1e-8||angle>Math.PI-.01)continue;
      const steps=Math.ceil(angle*60/Math.PI),den=Math.sin(angle);
      arcs.push(Array.from({length:steps+1},(_,step)=>{
        const t=step/steps,u=Math.sin((1-t)*angle)/den,v=Math.sin(t*angle)/den;
        return [start[0]*u+end[0]*v,start[1]*u+end[1]*v,start[2]*u+end[2]*v];
      }));
    }
    return {id:pattern.id,arcs};
  });
}

export function drawConstellationLines(ctx:CanvasRenderingContext2D,patterns:Pattern[],
  project:(...v:Vector)=>Point|null,width:number,height:number,aboveHorizonOnly:boolean,
  selected:string|null,started:Map<string,number>,now:number,reduced:boolean){
  let animating=false;
  ctx.save();
  ctx.lineWidth=1.15;
  ctx.lineCap='round';
  for(const pattern of patterns){
    const runs:{points:Point[];length:number}[]=[];
    for(const arc of pattern.arcs){
      let previous:Point|null=null,run:Point[]=[],length=0;
      for(const vector of arc){
        const point=aboveHorizonOnly&&vector[2]<0?null:project(...vector);
        const distance=point&&previous?Math.hypot(point[0]-previous[0],point[1]-previous[1]):Infinity;
        if(!point||!previous||distance>Math.max(width,height)/2||
          Math.max(point[0],previous[0])<0||Math.min(point[0],previous[0])>width||
          Math.max(point[1],previous[1])<0||Math.min(point[1],previous[1])>height){
          if(length>0)runs.push({points:run,length});
          run=[];length=0;
        }else{
          if(!run.length)run.push(previous);
          run.push(point);length+=distance;
        }
        previous=point;
      }
      if(length>0)runs.push({points:run,length});
    }
    if(!runs.length)continue;
    if(!started.has(pattern.id))started.set(pattern.id,now);
    const progress=reduced?1:Math.min(1,(now-started.get(pattern.id)!)/420);
    const reveal=1-(1-progress)**2;
    animating ||= progress<1;
    ctx.strokeStyle=pattern.id===selected?'rgba(187,218,255,.92)':'rgba(149,188,229,.62)';
    ctx.beginPath();
    for(const {points,length} of runs){
      let remaining=length*reveal;
      ctx.moveTo(...points[0]);
      for(let i=1;i<points.length&&remaining>0;i++){
        const [x,y]=points[i-1],point=points[i],segment=Math.hypot(point[0]-x,point[1]-y);
        if(remaining>=segment){ctx.lineTo(...point);remaining-=segment;}
        else{const fraction=remaining/segment;ctx.lineTo(x+(point[0]-x)*fraction,y+(point[1]-y)*fraction);break;}
      }
    }
    ctx.stroke();
  }
  ctx.restore();
  return animating;
}
