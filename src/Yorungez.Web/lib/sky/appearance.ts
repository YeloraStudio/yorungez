// Display transfer functions, not changes to astrometry or calibrated photometry.
export const clamp01=(x:number)=>Math.max(0,Math.min(1,x));
export function daylight(solarAltitude:number){return clamp01((solarAltitude+18)/22);}
export function starAppearance(magnitude:number){
 const flux=Math.pow(10,-.4*(magnitude-1));
 return {radius:Math.max(.32,Math.min(2.7,.5+Math.pow(flux,.32)*.9)),opacity:Math.max(.17,Math.min(1,.23+Math.pow(flux,.3)*.5))};
}
