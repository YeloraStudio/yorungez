import assert from 'node:assert/strict';
import test from 'node:test';
import {accountProxy,validMutation} from '../lib/server/account-proxy.ts';
test('production BFF sets its own HTTPS scheme and preserves the trusted public origin',async()=>{
 const previousFetch=globalThis.fetch,previousOrigin=process.env.YORUNGEZ_WEB_ORIGIN;
 try{
  process.env.YORUNGEZ_WEB_ORIGIN='https://yorungez.com';
  globalThis.fetch=async(_input,init)=>{
   const headers=init!.headers as Record<string,string>;
   assert.equal(headers['X-Forwarded-Proto'],'https');assert.equal(headers.Origin,'https://yorungez.com');
   // Only the proxy-observed (last) hop and the edge's visitor header reach the API.
   assert.equal(headers['X-Forwarded-For'],'172.70.1.10');assert.equal(headers['CF-Connecting-IP'],'203.0.113.7');
   return Response.json({code:'Identity.InvalidCredentials'},{status:401});
  };
  const response=await accountProxy(new Request('http://web:3000/api/account/login',{method:'POST',headers:{Origin:'https://yorungez.com','Content-Type':'application/json','X-Yorungez-Request':'1','X-Forwarded-Proto':'http','X-Forwarded-For':'192.0.2.99, 172.70.1.10','CF-Connecting-IP':'203.0.113.7'},body:'{}'}),'/api/v1/session/login');
  assert.equal(response.status,401);
 }finally{globalThis.fetch=previousFetch;if(previousOrigin===undefined)delete process.env.YORUNGEZ_WEB_ORIGIN;else process.env.YORUNGEZ_WEB_ORIGIN=previousOrigin}
});
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
