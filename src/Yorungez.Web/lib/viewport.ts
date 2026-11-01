export interface VisibleViewport {left:number;top:number;width:number;height:number}
export interface AnchorBounds {left:number;top:number;bottom:number}
/** CSS pixel geometry, including the keyboard/pinch-offset visual viewport. */
export function popupBounds(anchor:AnchorBounds,viewport:VisibleViewport,preferredWidth:number,contentHeight:number){
 const margin=Math.min(12,viewport.width/4,viewport.height/4);
 const width=Math.max(1,Math.min(preferredWidth,viewport.width-2*margin));
 const maxHeight=Math.max(1,viewport.height-2*margin),height=Math.min(contentHeight,maxHeight);
 const clamp=(n:number,min:number,max:number)=>Math.max(min,Math.min(n,max));
 const left=clamp(anchor.left,viewport.left+margin,viewport.left+viewport.width-margin-width);
 const below=anchor.bottom+6,top=clamp(below+height<=viewport.top+viewport.height-margin?below:anchor.top-height-6,viewport.top+margin,viewport.top+viewport.height-margin-height);
 return {left,top,width,maxHeight};
}
