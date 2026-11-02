import type {Camera} from './types.ts';
import {projectionScale} from './projection.ts';
import {daylight} from './appearance.ts';
const RAD=Math.PI/180;
// Inverse of the shared stereographic projector: ENU, azimuth clockwise from north.
export function screenRay(camera:Camera,width:number,height:number,x:number,y:number):[number,number,number]{
 const scale=projectionScale(camera,width,height),a=(x-width/2)/scale,b=(height/2-y)/scale,d=4+a*a+b*b;
 const r=4*a/d,u=4*b/d,f=(4-a*a-b*b)/d,az=camera.azimuth*RAD,alt=camera.altitude*RAD;
 return [r*Math.cos(az)-u*Math.sin(alt)*Math.sin(az)+f*Math.cos(alt)*Math.sin(az),-r*Math.sin(az)-u*Math.sin(alt)*Math.cos(az)+f*Math.cos(alt)*Math.cos(az),u*Math.cos(alt)+f*Math.sin(alt)];
}
// Equirectangular texture: authored rotation is illustrative, never a local horizon survey.
export function landscapeUv(az:number,alt:number):[number,number]{return [((az/360+.25)%1+1)%1,(90-alt)/180];}
// Keep the source's real detail; bounded retries are only for texture allocation.
export function uploadPanorama(sourceWidth:number,maxTextureSize:number,upload:(width:number)=>boolean):number{
 if(!Number.isFinite(sourceWidth)||!Number.isFinite(maxTextureSize))return 0;
 for(const width of [4096,2048,1024,512])if(width<=sourceWidth&&width<=maxTextureSize&&upload(width))return width;
 return 0;
}
const vertex=`attribute vec2 p;void main(){gl_Position=vec4(p,0.,1.);}`;
const fragment=`precision highp float;
uniform vec2 size;uniform float scale,az,alt,day,atmosphere,landscape,hasTexture,foreground,groundOpacity;
uniform vec3 sun;uniform sampler2D pano;
void main(){
 vec2 v=(gl_FragCoord.xy-size*.5)/scale;float d=4.+dot(v,v);
 vec3 c=vec3(cos(alt)*sin(az),cos(alt)*cos(az),sin(alt));
 vec3 r=vec3(cos(az),-sin(az),0.);vec3 u=vec3(-sin(alt)*sin(az),-sin(alt)*cos(az),cos(alt));
 vec3 ray=normalize(r*(4.*v.x/d)+u*(4.*v.y/d)+c*((4.-dot(v,v))/d));
 float elevation=asin(clamp(ray.z,-1.,1.));float horizon=exp(-max(0.,elevation)*3.8);
 float mu=clamp(dot(ray,sun),-1.,1.);float sunset=exp(-pow((asin(clamp(sun.z,-1.,1.))+.045)/.13,2.));
 vec3 night=mix(vec3(.032,.043,.068),vec3(.13,.15,.20),horizon*.7);
 vec3 clear=mix(vec3(.045,.19,.39),vec3(.43,.58,.68),pow(horizon,.8));
 clear+=vec3(.22,.18,.11)*pow(max(0.,mu),18.)+vec3(.6,.17,.035)*sunset*pow(horizon,2.)*pow(max(0.,mu*.5+.5),4.);
 vec3 sky=atmosphere>.5?mix(night,clear,day):vec3(.001,.002,.004);
 vec2 uv=vec2(fract(atan(ray.x,ray.y)/6.2831853+.25),.5-elevation/3.14159265);
 vec4 ground=hasTexture>.5?texture2D(pano,uv):vec4(vec3(.035),ray.z<0.?1.:0.);
 // Exposure only; photographs do not imply actual weather or local terrain.
 ground.rgb*=mix(.004,1.,day);ground.a*=landscape*groundOpacity;
 if(ray.z<0.&&groundOpacity<.95)sky=night;
 gl_FragColor=foreground>.5?ground:vec4(sky,1.);
}`;
export function createNaturalScene(onLoad:()=>void){
 const sky=document.createElement('canvas'),ground=document.createElement('canvas');
 sky.className='natural-sky';ground.className='photographic-ground';
 sky.setAttribute('aria-hidden','true');ground.setAttribute('aria-hidden','true');
 let alive=true,loaded=false,started=false,usable=true,alphaMask:Uint8Array|null=null,maskWidth=0,maskHeight=0;
 const image=new Image();image.decoding='async';
 const layers=[sky,ground].map((canvas,index)=>{
  const gl=canvas.getContext('webgl',{alpha:true,antialias:false,premultipliedAlpha:false});
  if(!gl)return null;
  try{
  const compile=(kind:number,text:string)=>{const sh=gl.createShader(kind)!;gl.shaderSource(sh,text);gl.compileShader(sh);if(!gl.getShaderParameter(sh,gl.COMPILE_STATUS))throw new Error('scene-shader');return sh;};
  const vs=compile(gl.VERTEX_SHADER,vertex),fs=compile(gl.FRAGMENT_SHADER,fragment),program=gl.createProgram()!;
  gl.attachShader(program,vs);gl.attachShader(program,fs);gl.linkProgram(program);if(!gl.getProgramParameter(program,gl.LINK_STATUS))throw new Error('scene-program');
  const buffer=gl.createBuffer(),texture=gl.createTexture();gl.bindBuffer(gl.ARRAY_BUFFER,buffer);gl.bufferData(gl.ARRAY_BUFFER,new Float32Array([-1,-1,1,-1,-1,1,-1,1,1,-1,1,1]),gl.STATIC_DRAW);
  const uniforms=Object.fromEntries(['size','scale','az','alt','day','atmosphere','landscape','hasTexture','foreground','groundOpacity','sun','pano'].map(n=>[n,gl.getUniformLocation(program,n)]));
  gl.bindTexture(gl.TEXTURE_2D,texture);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MIN_FILTER,gl.LINEAR);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MAG_FILTER,gl.LINEAR);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_S,gl.REPEAT);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_T,gl.CLAMP_TO_EDGE);
  gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,1,1,0,gl.RGBA,gl.UNSIGNED_BYTE,new Uint8Array([0,0,0,0]));
  return {canvas,gl,program,buffer,texture,vs,fs,uniforms,index};
  }catch{gl.getExtension("WEBGL_lose_context")?.loseContext();return null;}
 });
 usable=layers.every(Boolean);
 function lost(event:Event){event.preventDefault();usable=false;loaded=false;alphaMask=null;delete ground.dataset.panoramaSize;sky.style.display="none";ground.style.display="none";if(alive)onLoad();}
 for(const canvas of [sky,ground])canvas.addEventListener("webglcontextlost",lost);
 if(!usable){sky.style.display="none";ground.style.display="none";}
 image.onload=()=>{if(!alive||!usable)return;
  const sample=document.createElement('canvas');
  try{
   // Occlusion keeps its previous 2K sampling; retain alpha only, not a second RGBA image.
   maskWidth=Math.min(2048,image.naturalWidth);maskHeight=maskWidth/2;sample.width=maskWidth;sample.height=maskHeight;
   const ctx=sample.getContext('2d',{willReadFrequently:true});if(!ctx)throw new Error('panorama-mask');
   ctx.drawImage(image,0,0,maskWidth,maskHeight);const rgba=ctx.getImageData(0,0,maskWidth,maskHeight).data;
   alphaMask=new Uint8Array(maskWidth*maskHeight);for(let i=0;i<alphaMask.length;i++)alphaMask[i]=rgba[i*4+3];
   // The atmosphere pass needs only its 1x1 placeholder; the full photo belongs to the ground pass.
   const layer=layers[1];if(!layer)throw new Error('panorama-layer');const {gl,texture}=layer;
   gl.bindTexture(gl.TEXTURE_2D,texture);gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL,false);
   const width=uploadPanorama(image.naturalWidth,gl.getParameter(gl.MAX_TEXTURE_SIZE),size=>{
    if(gl.isContextLost())return false;
    if(size===image.naturalWidth)gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,gl.RGBA,gl.UNSIGNED_BYTE,image);
    else{sample.width=size;sample.height=size/2;ctx.drawImage(image,0,0,size,size/2);gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,gl.RGBA,gl.UNSIGNED_BYTE,sample);}
    return gl.getError()===gl.NO_ERROR;
   });
   if(!width)throw new Error('panorama-texture');
   ground.dataset.panoramaSize=`${width}x${width/2}`;loaded=true;onLoad();
  }catch{alphaMask=null;lost(new Event('texture-unavailable'));}
  finally{sample.width=sample.height=1;image.onload=null;image.onerror=null;image.src='';}
 };
 image.onerror=()=>{if(alive)lost(new Event('texture-unavailable'))};
 function occludes(az:number,alt:number){if(!usable||!loaded||!alphaMask)return alt<0;const [u,v]=landscapeUv(az,alt),x=Math.min(maskWidth-1,Math.floor(u*maskWidth)),y=Math.max(0,Math.min(maskHeight-1,Math.floor(v*maskHeight)));return alphaMask[y*maskWidth+x]>128;}
 function draw(camera:Camera,width:number,height:number,dpr:number,sun:[number,number,number],sunAlt:number,atmosphere:boolean,landscape:boolean,groundOpacity=1){
  if(!usable)return;
  if(landscape&&!started){started=true;image.src='/landscapes/stara-lesna.png';}
  for(const layer of layers){if(!layer)continue;const {gl,canvas,program,uniforms:u,index}=layer;
   const w=Math.round(width*dpr),h=Math.round(height*dpr);if(canvas.width!==w||canvas.height!==h){canvas.width=w;canvas.height=h;}
   gl.viewport(0,0,w,h);gl.useProgram(program);gl.bindBuffer(gl.ARRAY_BUFFER,layer.buffer);const pos=gl.getAttribLocation(program,'p');gl.enableVertexAttribArray(pos);gl.vertexAttribPointer(pos,2,gl.FLOAT,false,0,0);
   gl.uniform2f(u.size,w,h);gl.uniform1f(u.scale,projectionScale(camera,width,height)*dpr);gl.uniform1f(u.az,camera.azimuth*RAD);gl.uniform1f(u.alt,camera.altitude*RAD);gl.uniform1f(u.day,daylight(sunAlt));
   gl.uniform1f(u.atmosphere,+atmosphere);gl.uniform1f(u.landscape,+landscape);gl.uniform1f(u.hasTexture,+loaded);gl.uniform1f(u.foreground,index);gl.uniform1f(u.groundOpacity,groundOpacity);gl.uniform3f(u.sun,...sun);gl.uniform1i(u.pano,0);gl.bindTexture(gl.TEXTURE_2D,layer.texture);gl.drawArrays(gl.TRIANGLES,0,6);
  }
 }
 return {sky,ground,draw,occludes,get gpu(){return usable},dispose(){alive=false;for(const canvas of [sky,ground])canvas.removeEventListener("webglcontextlost",lost);image.onload=null;image.onerror=null;for(const l of layers)if(l){l.gl.deleteTexture(l.texture);l.gl.deleteBuffer(l.buffer);l.gl.deleteProgram(l.program);l.gl.deleteShader(l.vs);l.gl.deleteShader(l.fs);l.gl.getExtension('WEBGL_lose_context')?.loseContext();}sky.remove();ground.remove();}};
}
