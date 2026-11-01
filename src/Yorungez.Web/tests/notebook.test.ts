import assert from 'node:assert/strict';import test from 'node:test';
import {validateEntry,notebookExport,type NotebookEntry} from '../lib/notebook/model.ts';
const note:NotebookEntry={id:'example-note',kind:'note',revision:1,body:'A public test note',createdAtUtc:'2026-10-31T20:00:00Z',updatedAtUtc:'2026-10-31T20:00:00Z'};
test('personal notes do not require target, observation time or coordinates; empty and malformed records fail',()=>{
 assert.equal(validateEntry(note),note);assert.equal(note.target,undefined);assert.equal(note.location,undefined);assert.equal(note.instantUtc,undefined);
 assert.throws(()=>validateEntry({...note,body:' '}));assert.throws(()=>validateEntry({...note,body:'a'.repeat(8001)}));assert.throws(()=>validateEntry({...note,location:{latitude:91,longitude:0,elevationMeters:null}}));
 const favorite=validateEntry({...note,id:'favorite:jupiter',kind:'favorite',body:undefined,target:{id:'jupiter',name:'Jupiter'}});assert.equal(favorite.id,'favorite:jupiter');assert.throws(()=>validateEntry({...favorite,id:'other-id'}));
});
test('explicit export retains both live and recoverable records; revisions are enforced by the server',()=>{
 const trashed={...note,id:'trash-example',deletedAtUtc:'2026-11-01T00:00:00Z',revision:2};const exported=notebookExport([note,trashed]);
 assert.equal(exported.version,2);assert.equal(exported.entries.length,2);assert.equal(exported.entries[1].body,note.body);assert.ok(exported.entries[1].deletedAtUtc);
});
