import assert from 'node:assert/strict';import test from 'node:test';
import {enteredLocation,enteredObservationTime,locationSnapshot,observerAtSavedLocation} from '../lib/notebook/inventory.ts';
import {notebookExport,validateEntry,type NotebookEntry} from '../lib/notebook/model.ts';
test('saved coordinate snapshots retain precision/unknown height and never carry device measurements into a reused map point',()=>{
 const source={latitude:41.0123456789,longitude:28.987654321,elevationMeters:null,placeName:'Public sample',instantUtc:'2026-10-31T20:00:00Z',source:'device' as const,accuracyMeters:12,measuredAtUtc:'2026-10-31T19:59:59Z'};
 const snapshot=locationSnapshot(source);source.latitude=0;source.placeName='Changed';assert.equal(snapshot.latitude,41.0123456789);assert.equal(snapshot.placeName,'Public sample');assert.equal(snapshot.elevationMeters,null);
 const next=observerAtSavedLocation(snapshot,source);assert.equal(next.instantUtc,source.instantUtc);assert.equal(next.source,'manual');assert.equal(next.accuracyMeters,undefined);assert.equal(next.measuredAtUtc,undefined);
 assert.deepEqual(enteredLocation('0','-0','',''),{latitude:0,longitude:-0,elevationMeters:null,placeName:undefined});assert.equal(enteredLocation('41,5','29,2','-5',' test ').latitude,41.5);
 for(const args of [['','0','',''],['91','0','',''],['0','181','',''],['0','0','Infinity',''],['0','0','10001','']])assert.throws(()=>enteredLocation(...args as [string,string,string,string]));
});
test('unknown observation time remains absent; explicitly entered historical and DST-fold times resolve without simulation inference',()=>{
 assert.throws(()=>enteredObservationTime('','0','0','UTC'));assert.throws(()=>enteredObservationTime('2026-10-30','','0','UTC'));assert.throws(()=>enteredObservationTime('2026-10-30','24','0','UTC'));
 assert.equal(enteredObservationTime('1988-04-12','21','15','UTC'),'1988-04-12T21:15:00Z');
 assert.throws(()=>enteredObservationTime('2026-11-01','1','30','America/New_York'));
 assert.equal(enteredObservationTime('2026-11-01','1','30','America/New_York','earlier'),'2026-11-01T05:30:00Z');assert.equal(enteredObservationTime('2026-11-01','1','30','America/New_York','later'),'2026-11-01T06:30:00Z');
 for(const occurrence of ['reject','earlier','later'] as const)assert.throws(()=>enteredObservationTime('2026-03-08','2','30','America/New_York',occurrence));
});
test('four inventory concepts stay distinct and v2 export retains observations and recoverable locations',()=>{
 const base={id:'public-example',revision:1,createdAtUtc:'2026-10-31T20:00:00Z',updatedAtUtc:'2026-10-31T20:00:00Z'},observation:NotebookEntry={...base,kind:'observation',body:'I saw a bright object',observationConfirmed:true};
 assert.equal(validateEntry(observation).observedAtUtc,undefined);assert.throws(()=>validateEntry({...observation,observationConfirmed:false}));assert.throws(()=>validateEntry({...observation,instantUtc:'2026-10-31T22:00:00Z'}));
 assert.throws(()=>validateEntry({...base,kind:'place'}));const place:NotebookEntry={...base,id:'public-place',kind:'place',location:{latitude:0,longitude:0,elevationMeters:null},deletedAtUtc:'2026-10-31T20:01:00Z'};validateEntry(place);
 assert.throws(()=>validateEntry({...place,observedAtUtc:'2026-10-30T00:00:00Z'}));const exported=notebookExport([observation,place]);assert.equal(exported.version,2);assert.equal(exported.entries[0].observationConfirmed,true);assert.ok(exported.entries[1].deletedAtUtc);
});
