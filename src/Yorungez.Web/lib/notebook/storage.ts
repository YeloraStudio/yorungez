import {accountRequest} from '../account.ts';
import {validateEntry,type NotebookEntry} from './model.ts';
import type {Language} from '../sky/types.ts';
// Personal records are always account-owned server data. No browser database or offline writes.
export async function readNotebook(owner:string,language:Language){
 const result=await accountRequest('/api/notebook',language,undefined,owner);
 if(result.userId!==owner)throw new Error('Notebook.AccountChanged');
 return (result.entries as NotebookEntry[]).map(validateEntry);
}
export async function writeNotebook(draft:Omit<NotebookEntry,'revision'>,expected:number,owner:string,language:Language){
 const entry=await accountRequest('/api/notebook',language,{id:draft.id,kind:draft.kind,expectedRevision:expected,
  body:draft.body??null,target:draft.target??null,instantUtc:draft.instantUtc??null,location:draft.location??null,deleted:!!draft.deletedAtUtc,
  observedAtUtc:draft.observedAtUtc??null,observationConfirmed:draft.observationConfirmed??false},owner);
 return validateEntry(entry as NotebookEntry);
}
