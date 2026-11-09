import type { ArtMesh } from './art.ts';

// Use the atmosphere's existing context and the same projected mesh as the
// Canvas fallback. RGB screen blending preserves the stars and clears the
// black areas in the original artwork.
export function createWebGlArt(gl:WebGLRenderingContext){
  const vertex=gl.createShader(gl.VERTEX_SHADER),fragment=gl.createShader(gl.FRAGMENT_SHADER);
  const program=gl.createProgram(),buffer=gl.createBuffer();
  const textures=new Map<HTMLImageElement,WebGLTexture>();
  function dispose(){
    for(const texture of textures.values())gl.deleteTexture(texture);
    gl.deleteBuffer(buffer);gl.deleteProgram(program);gl.deleteShader(vertex);gl.deleteShader(fragment);
  }
  if(!vertex||!fragment||!program||!buffer){dispose();return null;}
  gl.shaderSource(vertex,`
    attribute vec4 position;
    uniform vec2 size;
    varying vec2 uv;
    void main(){
      gl_Position=vec4(2.*position.x/size.x-1.,1.-2.*position.y/size.y,0.,1.);
      uv=position.zw;
    }`);
  gl.shaderSource(fragment,`
    precision mediump float;
    uniform sampler2D picture;
    uniform float opacity;
    varying vec2 uv;
    void main(){
      vec4 pixel=texture2D(picture,uv);
      gl_FragColor=vec4(pixel.rgb*pixel.a*opacity,1.);
    }`);
  gl.compileShader(vertex);gl.compileShader(fragment);
  gl.attachShader(program,vertex);gl.attachShader(program,fragment);gl.linkProgram(program);
  if(!gl.getProgramParameter(program,gl.LINK_STATUS)){dispose();return null;}
  const position=gl.getAttribLocation(program,'position'),size=gl.getUniformLocation(program,'size');
  const opacity=gl.getUniformLocation(program,'opacity'),picture=gl.getUniformLocation(program,'picture');
  let data=new Float32Array(0);

  function bindImage(image:HTMLImageElement){
    const cached=textures.get(image);
    if(cached){gl.bindTexture(gl.TEXTURE_2D,cached);return true;}
    const texture=gl.createTexture();
    if(!texture)return false;
    gl.bindTexture(gl.TEXTURE_2D,texture);
    gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MIN_FILTER,gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MAG_FILTER,gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_S,gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_T,gl.CLAMP_TO_EDGE);
    gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,gl.RGBA,gl.UNSIGNED_BYTE,image);
    textures.set(image,texture);
    return true;
  }

  function draw(meshes:ArtMesh[],width:number,height:number){
    const length=meshes.reduce((total,mesh)=>total+mesh.vertices.length,0);
    if(data.length<length)data=new Float32Array(Math.max(length,data.length*2));
    let offset=0;
    for(const mesh of meshes){data.set(mesh.vertices,offset);offset+=mesh.vertices.length;}
    gl.useProgram(program);
    gl.bindBuffer(gl.ARRAY_BUFFER,buffer);
    gl.bufferData(gl.ARRAY_BUFFER,data.subarray(0,length),gl.STREAM_DRAW);
    gl.enableVertexAttribArray(position);
    gl.vertexAttribPointer(position,4,gl.FLOAT,false,0,0);
    gl.uniform2f(size,width,height);
    gl.activeTexture(gl.TEXTURE0);
    gl.uniform1i(picture,0);
    gl.enable(gl.BLEND);
    gl.blendFuncSeparate(gl.ONE,gl.ONE_MINUS_SRC_COLOR,gl.ZERO,gl.ONE);
    offset=0;
    try{
      for(const mesh of meshes){
        const count=mesh.vertices.length/4;
        if(bindImage(mesh.image)){
          gl.uniform1f(opacity,mesh.opacity);
          gl.drawArrays(gl.TRIANGLES,offset,count);
        }
        offset+=count;
      }
    }finally{gl.disable(gl.BLEND);}
    if(textures.size>48){
      const visible=new Set(meshes.map(mesh=>mesh.image));
      for(const [image,texture] of textures){
        if(textures.size<=48)break;
        if(!visible.has(image)){gl.deleteTexture(texture);textures.delete(image);}
      }
    }
  }
  return {draw,dispose};
}
