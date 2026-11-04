import type { Camera } from "./types.ts";
const RAD = Math.PI / 180;
export function projectionScale(camera: Camera, width: number, height: number) {
  if(camera.projection==='perspective')return Math.max(width,height)/(2*Math.tan(camera.fieldOfView*RAD/2));
  return Math.max(width, height) / (4 * Math.tan(camera.fieldOfView * RAD / 4));
}
export function projector(camera: Camera, width: number, height: number) {
  const az = camera.azimuth * RAD, alt = camera.altitude * RAD;
  const cx = Math.cos(alt) * Math.sin(az), cy = Math.cos(alt) * Math.cos(az), cz = Math.sin(alt);
  const rx = Math.cos(az), ry = -Math.sin(az);
  const ux = -Math.sin(alt) * Math.sin(az), uy = -Math.sin(alt) * Math.cos(az), uz = Math.cos(alt);
  const scale = projectionScale(camera, width, height);
  return (x: number, y: number, z: number): [number, number] | null => {
    const depth = x * cx + y * cy + z * cz;
    if (depth <= (camera.projection==='perspective'?0:-0.999999)) return null;
    const k = camera.projection==='perspective'?scale/depth:2 * scale / (1 + depth),roll=(camera.roll??0)*RAD;
    const r=x*rx+y*ry,u=x*ux+y*uy+z*uz;
    return [width/2+k*(r*Math.cos(roll)-u*Math.sin(roll)),height/2-k*(u*Math.cos(roll)+r*Math.sin(roll))];
  };
}
export function horizontalVector(azimuth: number, altitude: number): [number, number, number] {
  const az = azimuth * RAD, alt = altitude * RAD;
  return [Math.cos(alt) * Math.sin(az), Math.cos(alt) * Math.cos(az), Math.sin(alt)];
}
export function normalizedCamera(camera: Camera): Camera {
  return { azimuth: ((camera.azimuth % 360) + 360) % 360,
    altitude: Math.max(-90, Math.min(90, camera.altitude)), fieldOfView: Math.max(0.6, Math.min(camera.projection==='perspective'?120:330, camera.fieldOfView)),
    ...(camera.roll===undefined?{}:{roll:((camera.roll+180)%360+360)%360-180}),...(camera.projection?{projection:camera.projection}:{}) };
}
export function equatorialVector(matrix: Float64Array, raHours: number, decDegrees: number): [number, number, number] {
  const ra = raHours * 15 * RAD, dec = decDegrees * RAD;
  const x = Math.cos(dec) * Math.cos(ra), y = Math.cos(dec) * Math.sin(ra), z = Math.sin(dec);
  return [matrix[0]*x+matrix[3]*y+matrix[6]*z, matrix[1]*x+matrix[4]*y+matrix[7]*z, matrix[2]*x+matrix[5]*y+matrix[8]*z];
}
export function pickObject(points: Float32Array, ids: string[], x: number, y: number, radius = 13) {
  let found: string | null = null, best = radius * radius;
  for (let i = 0; i < ids.length; i++) {
    const dx = points[i * 2] - x, dy = points[i * 2 + 1] - y;
    const squared = dx * dx + dy * dy;
    if (squared < best) { best = squared; found = ids[i]; }
  }
  return found;
}
