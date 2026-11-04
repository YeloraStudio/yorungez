import assert from 'node:assert/strict';
import test from 'node:test';
import {languageFromCookie,languageCookie,supportedLanguage} from '../lib/language-preference.ts';
import {accountProxy} from '../lib/server/account-proxy.ts';

test('language cookie supports only exact EN/TR values and has no account identity',()=>{
 assert.equal(languageFromCookie(''),undefined);
 assert.equal(languageFromCookie('other=x; yorungez-language=tr; unrelated=1'),'tr');
 for(const value of ['TR','fr','../../tr','en%0a',''])assert.equal(languageFromCookie('yorungez-language='+value),undefined);
 assert.equal(supportedLanguage(null),false);
 assert.match(languageCookie('tr',true),/^yorungez-language=tr; Path=\/; Max-Age=31536000; SameSite=Lax; Secure$/);
 assert.equal(languageCookie('en',false).includes('Secure'),false);
});

test('language mutation forwards the signed-in owner and JSON but does not forward the preference cookie',async()=>{
 const previous=globalThis.fetch;
 try{
  globalThis.fetch=async(input,init)=>{
   assert.equal(String(input),'http://127.0.0.1:5187/api/v1/auth/language');
   const headers=init!.headers as Record<string,string>;
   assert.equal(headers.Cookie,'yorungez-session=opaque');
   assert.equal(headers['X-Yorungez-Account'],'public-owner');
   assert.equal(init!.body,JSON.stringify({preferredLanguage:'tr'}));
   return Response.json({id:'public-owner',preferredLanguage:'tr'});
  };
  const response=await accountProxy(new Request('https://yorungez.test/api/account/language',{method:'POST',
   headers:{Origin:'https://yorungez.test','X-Yorungez-Request':'1','X-Yorungez-Account':'public-owner','Content-Type':'application/json',Cookie:'yorungez-session=opaque; yorungez-language=en'},body:JSON.stringify({preferredLanguage:'tr'})}),'/api/v1/auth/language');
  assert.equal(response.status,200);assert.match(response.headers.get('Cache-Control')!,/no-store/);
 }finally{globalThis.fetch=previous}
});
