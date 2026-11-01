import assert from 'node:assert/strict';import test from 'node:test';
import {monthGrid,clampDate,moveCalendarDay} from '../lib/date-picker.ts';
import {cardinalIndex,angularFists,observingBrief} from '../lib/location/direction-guide.ts';
test('custom calendar navigation retains valid leap days, Monday weeks and bounded model dates',()=>{
 const grid=monthGrid('2024-02-29');assert.equal(grid.length,42);assert.equal(grid[0].dayOfWeek,1);assert.equal(grid.filter(d=>d.month===2).length,29);
 assert.equal(moveCalendarDay('2024-02-29','PageDown'),'2024-03-29');assert.equal(moveCalendarDay('2024-02-29','PageUp',true),'2023-02-28');
 assert.equal(moveCalendarDay('2026-11-01','Home'),'2026-10-26');assert.equal(moveCalendarDay('2026-10-31','ArrowRight'),'2026-11-01');assert.equal(moveCalendarDay('2026-10-31','Escape'),null);
 assert.equal(clampDate('1999-12-31','2000-01-02','2035-12-30'),'2000-01-02');assert.throws(()=>clampDate('2026-02-30','2000-01-02','2035-12-30'));
});
test('manual directions wrap at north; binocular instructions never imply below-horizon or daylight visibility',()=>{
 assert.equal(cardinalIndex(359),0);assert.equal(cardinalIndex(45),1);assert.equal(cardinalIndex(-90),6);assert.throws(()=>cardinalIndex(NaN));
 assert.equal(angularFists(45),4.5);assert.equal(angularFists(-10),0);assert.equal(angularFists(90),9);
 assert.equal(observingBrief({id:'jupiter',altitude:-1},-20),'below');assert.equal(observingBrief({id:'jupiter',altitude:30},10),'twilight');
 assert.equal(observingBrief({id:'jupiter',altitude:30},-12),'night');assert.equal(observingBrief({id:'sun',altitude:30},30),'solar');assert.equal(observingBrief({id:'jupiter',altitude:30},null),'unknown');
});
