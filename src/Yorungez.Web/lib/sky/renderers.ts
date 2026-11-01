export type RendererKind = "canvas" | "svg" | "webgl";
export interface DrawData { points: Float32Array; radii: Float32Array; colors: string[]; count: number; width: number; height: number; dpr: number; opacities?:Float32Array }
export interface StarRenderer { element: HTMLElement | SVGSVGElement; draw(data: DrawData): void; dispose(): void }

export function createRenderer(kind: RendererKind): StarRenderer {
  if (kind === "svg") {
    const element = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    const circles: SVGCircleElement[] = [];
    element.setAttribute("aria-hidden", "true");
    return { element, draw(data) {
      element.setAttribute("viewBox", `0 0 ${data.width} ${data.height}`);
      for (let i = 0; i < data.count; i++) {
        let circle = circles[i];
        if (!circle) { circle = document.createElementNS(element.namespaceURI, "circle") as SVGCircleElement; element.appendChild(circle); circles.push(circle); }
        const x = data.points[i * 2], y = data.points[i * 2 + 1];
        const visible = Number.isFinite(x) && x > -10 && x < data.width + 10 && y > -10 && y < data.height + 10;
        circle.style.display = visible ? "" : "none";
        if (visible) { circle.setAttribute("cx", String(x)); circle.setAttribute("cy", String(y)); circle.setAttribute("r", String(data.radii[i])); circle.setAttribute("fill", data.colors[i]); circle.setAttribute("opacity",String(data.opacities?.[i]??1)); }
      }
    }, dispose() { element.remove(); } };
  }
  const element = document.createElement("canvas");
  element.setAttribute("aria-hidden", "true");
  if (kind === "canvas") {
    const sprites=new Map<string,HTMLCanvasElement>();
    const ctx = element.getContext("2d", { alpha: true });
    if (!ctx) throw new Error("canvas-unavailable");
    return { element, draw(data) {
      const w = Math.round(data.width * data.dpr), h = Math.round(data.height * data.dpr);
      if (element.width !== w || element.height !== h) { element.width = w; element.height = h; }
      ctx.setTransform(data.dpr, 0, 0, data.dpr, 0, 0); ctx.clearRect(0, 0, data.width, data.height);
      for (let i = 0; i < data.count; i++) {
        const x = data.points[i * 2], y = data.points[i * 2 + 1];
        if (!Number.isFinite(x) || x < -10 || x > data.width + 10 || y < -10 || y > data.height + 10) continue;
        const radius=data.radii[i];if(radius<=0)continue;
        const key=data.colors[i]+":"+Math.round(radius*8);let sprite=sprites.get(key);
        if(!sprite){sprite=document.createElement("canvas");sprite.width=sprite.height=48;const brush=sprite.getContext("2d")!;
          const rgb=[1,3,5].map(k=>parseInt(data.colors[i].slice(k,k+2),16)).join(",");
          const halo=brush.createRadialGradient(24,24,0,24,24,24);halo.addColorStop(0,`rgba(${rgb},.65)`);halo.addColorStop(.15,`rgba(${rgb},.2)`);halo.addColorStop(.45,`rgba(${rgb},.035)`);halo.addColorStop(1,`rgba(${rgb},0)`);brush.fillStyle=halo;brush.fillRect(0,0,48,48);sprites.set(key,sprite);}
        ctx.globalAlpha=data.opacities?.[i]??1;
        if(radius>.75){const spread=radius*5;ctx.drawImage(sprite,x-spread,y-spread,spread*2,spread*2);}
        ctx.globalAlpha=Math.min(1,.3+radius*.45)*(data.opacities?.[i]??1);ctx.beginPath();ctx.fillStyle=data.colors[i];ctx.arc(x,y,radius,0,Math.PI*2);ctx.fill();ctx.globalAlpha=1;
      }
    }, dispose() { element.remove(); } };
  }
  const gl = element.getContext("webgl", { alpha: true, antialias: false, premultipliedAlpha: false });
  if (!gl) throw new Error("webgl-unavailable");
  function shader(type: number, source: string) {
    const shader = gl!.createShader(type)!; gl!.shaderSource(shader, source); gl!.compileShader(shader);
    if (!gl!.getShaderParameter(shader, gl!.COMPILE_STATUS)) throw new Error("shader-compilation");
    return shader;
  }
  const vertex = shader(gl.VERTEX_SHADER, "attribute vec2 p; attribute float r; attribute vec3 c; attribute float a; varying float alpha; varying vec3 color; uniform vec2 size; uniform float dpr; void main(){gl_Position=vec4(p.x/size.x*2.0-1.0,1.0-p.y/size.y*2.0,0,1);gl_PointSize=r*2.0*dpr;color=c;alpha=a;}");
  const fragment = shader(gl.FRAGMENT_SHADER, "precision mediump float; varying float alpha; varying vec3 color; void main(){if(distance(gl_PointCoord,vec2(0.5))>0.5)discard;gl_FragColor=vec4(color,alpha);}");
  const program = gl.createProgram()!; gl.attachShader(program, vertex); gl.attachShader(program, fragment); gl.linkProgram(program);
  if (!gl.getProgramParameter(program, gl.LINK_STATUS)) throw new Error("shader-link");
  const buffer = gl.createBuffer()!;
  const position = gl.getAttribLocation(program, "p"), radius = gl.getAttribLocation(program, "r"), color = gl.getAttribLocation(program, "c"), alpha = gl.getAttribLocation(program,"a");
  let values = new Float32Array(0);
  return { element, draw(data) {
    const w = Math.round(data.width * data.dpr), h = Math.round(data.height * data.dpr);
    if (element.width !== w || element.height !== h) { element.width = w; element.height = h; }
    gl.viewport(0, 0, w, h); gl.clearColor(0, 0, 0, 0); gl.clear(gl.COLOR_BUFFER_BIT); gl.useProgram(program);
    if (values.length !== data.count * 7) values = new Float32Array(data.count * 7);
    for (let i = 0; i < data.count; i++) {
      const k = i * 7, hex = data.colors[i];
      values[k] = Number.isFinite(data.points[i * 2]) ? data.points[i * 2] : -10000;
      values[k + 1] = Number.isFinite(data.points[i * 2 + 1]) ? data.points[i * 2 + 1] : -10000; values[k + 2] = data.radii[i];
      values[k + 3] = parseInt(hex.slice(1, 3), 16) / 255; values[k + 4] = parseInt(hex.slice(3, 5), 16) / 255; values[k + 5] = parseInt(hex.slice(5, 7), 16) / 255; values[k+6]=data.opacities?.[i]??1;
    }
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer); gl.bufferData(gl.ARRAY_BUFFER, values, gl.DYNAMIC_DRAW);
    for (const [location, size, offset] of [[position, 2, 0], [radius, 1, 8], [color, 3, 12], [alpha,1,24]]) {
      gl.enableVertexAttribArray(location); gl.vertexAttribPointer(location, size, gl.FLOAT, false, 28, offset);
    }
    gl.uniform2f(gl.getUniformLocation(program, "size"), data.width, data.height);
    gl.uniform1f(gl.getUniformLocation(program, "dpr"), data.dpr);
    gl.drawArrays(gl.POINTS, 0, data.count);
  }, dispose() { gl.deleteBuffer(buffer); gl.deleteProgram(program); gl.deleteShader(vertex); gl.deleteShader(fragment); gl.getExtension("WEBGL_lose_context")?.loseContext(); element.remove(); } };
}
