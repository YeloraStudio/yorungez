import assert from 'node:assert/strict';
import test from 'node:test';
import {accountProxy,validMutation} from '../lib/server/account-proxy.ts';
test('account mutations reject absent/cross-site origin, ordinary forms and absent request headers',async()=>{
 const url='https://yorungez.test/api/account/login';
 const make=(headers:Record<string,string>)=>new Request(url,{method:'POST',headers,body:'{}'});
 const good={'Origin':'https://yorungez.test','Content-Type':'application/json','X-Yorungez-Request':'1'};
 assert.equal(validMutation(make(good)),true);
 assert.equal(validMutation(new Request('http://localhost:5199/api/account/login',{method:'POST',headers:{Origin:'http://127.0.0.1:5199',Host:'127.0.0.1:5199','Content-Type':'application/json','X-Yorungez-Request':'1'},body:'{}'})),true);
 for(const bad of [{...good,Origin:'https://other.test'},{...good,'X-Yorungez-Request':''},{...good,'Content-Type':'text/plain'},{...good,'Sec-Fetch-Site':'cross-site'}]){
  assert.equal(validMutation(make(bad)),false);assert.equal((await accountProxy(make(bad),'/api/v1/session/login')).status,403);
 }
});
test('BFF forwards only the session cookie, never caches personal records, and reports an outage without inventing a save',async()=>{
 const previous=globalThis.fetch;
 try{
  globalThis.fetch=async(input,init)=>{
   assert.equal(String(input),'http://127.0.0.1:5187/api/v1/notebook/');
   assert.equal((init!.headers as Record<string,string>).Cookie,'yorungez-session=opaque');
   assert.equal((init!.headers as Record<string,string>)['X-Yorungez-Account'],'public-owner');
   assert.equal(init!.cache,'no-store');
   assert.equal((init!.headers as Record<string,string>)['Accept-Language'],'en');
   return Response.json({userId:'public-owner',entries:[]});
  };
  const request=new Request('https://yorungez.test/api/notebook',{headers:{Cookie:'other=value; yorungez-session=opaque','X-Yorungez-Account':'public-owner'}});
  const response=await accountProxy(request,'/api/v1/notebook/');assert.equal(response.status,200);assert.match(response.headers.get('Cache-Control')!,/no-store/);
  globalThis.fetch=async()=>{throw new Error('Synthetic private failure')};
  const failed=await accountProxy(request,'/api/v1/notebook/');assert.equal(failed.status,503);assert.equal((await failed.json()).code,'Common.Unavailable');
 }finally{globalThis.fetch=previous}
});


test('an anonymous session check returns signed-out without requiring the account backend',async()=>{
 const prior=globalThis.fetch;let calls=0;try{globalThis.fetch=async()=>{calls++;throw new Error('backend stopped')};
 const result=await accountProxy(new Request('https://yorungez.test/api/account/me'),'/api/v1/auth/me');
 assert.equal(result.status,401);assert.equal(calls,0);assert.match(result.headers.get('Cache-Control')!,/no-store/);
 }finally{globalThis.fetch=prior}
});
