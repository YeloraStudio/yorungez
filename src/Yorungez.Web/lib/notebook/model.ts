export interface NotebookTarget {id:string;name:string}
export interface NotebookLocation {latitude:number;longitude:number;elevationMeters:number|null;placeName?:string}
export interface NotebookEntry {id:string;kind:'favorite'|'note'|'observation'|'place';revision:number;createdAtUtc:string;updatedAtUtc:string;deletedAtUtc?:string;body?:string;target?:NotebookTarget;instantUtc?:string;location?:NotebookLocation;observedAtUtc?:string;observationConfirmed?:boolean}
export function validateEntry(entry:NotebookEntry){
 if(!entry.id||!['note','favorite','observation','place'].includes(entry.kind)||!Number.isInteger(entry.revision)||entry.revision<1)throw new Error('invalid-note');
 if(!Number.isFinite(Date.parse(entry.createdAtUtc))||!Number.isFinite(Date.parse(entry.updatedAtUtc)))throw new Error('invalid-note');
 if((entry.body?.length??0)>8000||(['note','observation'].includes(entry.kind)&&!entry.body?.trim()))throw new Error('invalid-note');
 if(entry.kind==='observation'&&(!entry.observationConfirmed||entry.instantUtc))throw new Error('invalid-note');
 if(entry.kind!=='observation'&&(entry.observationConfirmed||entry.observedAtUtc))throw new Error('invalid-note');
 if(entry.kind==='place'&&(!entry.location||entry.target||entry.instantUtc))throw new Error('invalid-note');
 if(entry.observedAtUtc&&!Number.isFinite(Date.parse(entry.observedAtUtc)))throw new Error('invalid-note');
 if(entry.kind==='favorite'&&(!entry.target||entry.id!==`favorite:${entry.target.id}`))throw new Error('invalid-note');
 if(entry.target&&(!entry.target.id||!entry.target.name))throw new Error('invalid-note');
 if(entry.instantUtc&&!Number.isFinite(Date.parse(entry.instantUtc)))throw new Error('invalid-note');
 if(entry.location){const l=entry.location;if(!Number.isFinite(l.latitude)||Math.abs(l.latitude)>90||!Number.isFinite(l.longitude)||Math.abs(l.longitude)>180||(l.elevationMeters!==null&&(!Number.isFinite(l.elevationMeters)||l.elevationMeters< -500||l.elevationMeters>10000)))throw new Error('invalid-note');}
 return entry;
}
export function notebookExport(entries:NotebookEntry[]){return {format:'yorungez-notebook',version:2,exportedAtUtc:new Date().toISOString(),entries};}
