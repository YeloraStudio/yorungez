import type {Language} from './sky/types.ts';
export interface AccountUser {id:string;email:string;emailConfirmed:boolean;firstName:string|null;lastName:string|null}
export class AccountError extends Error {status:number;constructor(code:string,status:number){super(code);this.status=status}}
export async function accountRequest(path:string,language:Language,body?:unknown,owner?:string){
 const response=await fetch(path,{method:body===undefined?'GET':'POST',credentials:'same-origin',cache:'no-store',
  headers:{'Accept-Language':language,...(body===undefined?{}:{'Content-Type':'application/json','X-Yorungez-Request':'1'}),...(owner?{'X-Yorungez-Account':owner}:{})},
  body:body===undefined?undefined:JSON.stringify(body),signal:AbortSignal.timeout(18000)}).catch(()=>{throw new AccountError(typeof navigator!=='undefined'&&navigator.onLine===false?'Account.Offline':'Common.Unavailable',503)});
 const data=await response.json().catch(()=>({}));
 if(!response.ok)throw new AccountError(data.code??'Common.Unexpected',response.status);
 return data;
}

export const accountName=(user:AccountUser)=>[user.firstName,user.lastName].filter(Boolean).join(' ');
