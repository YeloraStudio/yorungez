// Exploration changes only the photographic overlay, never the horizon calculation.
export function terrainOpacity(altitude:number,selectedOccluded:boolean){
 const lookDown=Math.max(0,Math.min(1,(5-altitude)/20));
 return Math.min(1-lookDown*.9,selectedOccluded ? .12 : 1);
}
