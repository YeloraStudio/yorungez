import type {PlanInterval} from './planning.ts';
// Keyboard activation must stay inside the chosen bar, including a body's second interval.
export function intervalInstant(interval:PlanInterval,best:string|null,fraction:number|null):string {
 const start=Date.parse(interval.startUtc),end=Date.parse(interval.endUtc),preferred=best?Date.parse(best):NaN;
 const instant=fraction===null&&preferred>start&&preferred<end?preferred:start+(end-start)*(fraction===null?.5:Math.max(.01,Math.min(.99,fraction)));
 return new Date(instant).toISOString();
}
