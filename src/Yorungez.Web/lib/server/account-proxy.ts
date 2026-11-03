import {readJson} from '../http/read-json.ts';
const privateHeaders={'Cache-Control':'no-store, private','Vary':'Cookie','Content-Type':'application/json'};
export function validMutation(request:Request){
 const url=new URL(request.url);
 // Next's internal request URL may use localhost while the browser uses 127.0.0.1.
 // Production behind a TLS proxy supplies an explicit trusted public origin.
 const origin=process.env.YORUNGEZ_WEB_ORIGIN??`${url.protocol}//${request.headers.get('Host')??url.host}`;
 return request.headers.get('Origin')===origin&&request.headers.get('X-Yorungez-Request')==='1'
  &&request.headers.get('Content-Type')?.split(';')[0].trim()==='application/json'
  &&request.headers.get('Sec-Fetch-Site')!=='cross-site';
}
export async function accountProxy(request:Request,path:string){
 if(request.method!=='GET'&&!validMutation(request))return Response.json({code:'Common.Forbidden'},{status:403,headers:privateHeaders});
 try{
  const headers:Record<string,string>={'Accept-Language':request.headers.get('Accept-Language')==='tr'?'tr':'en','X-Yorungez-Request':'1'};
  const cookie=(request.headers.get('Cookie')??'').split(';').map(s=>s.trim()).filter(s=>/^(?:__Host-)?yorungez-session(?:C\d+)?=/.test(s)).join('; ');
  if(path==='/api/v1/auth/me'&&!cookie)return Response.json({code:'Identity.InvalidCredentials'},{status:401,headers:privateHeaders});
  if(cookie)headers.Cookie=cookie;
  const owner=request.headers.get('X-Yorungez-Account');if(owner)headers['X-Yorungez-Account']=owner;
  headers.Origin=request.headers.get('Origin')??new URL(request.url).origin;
  // This server is an explicitly trusted API proxy; never forward the client's supplied proto.
  if(process.env.YORUNGEZ_WEB_ORIGIN?.startsWith('https://'))headers['X-Forwarded-Proto']='https';
  // Only the last X-Forwarded-For entry is passed on: the address the reverse proxy itself saw.
  // The API trusts CF-Connecting-IP only when that address is a Cloudflare edge, so neither
  // value lets a caller pick its own rate-limit partition.
  const seen=request.headers.get('X-Forwarded-For')?.split(',').at(-1)?.trim();
  if(seen)headers['X-Forwarded-For']=seen;
  const visitor=request.headers.get('CF-Connecting-IP')?.trim();
  if(visitor)headers['CF-Connecting-IP']=visitor;
  let body:string|undefined;
  if(request.method!=='GET'){headers['Content-Type']='application/json';try{body=JSON.stringify(await readJson(request,65536))}catch{return Response.json({code:'Common.InvalidInput'},{status:400,headers:privateHeaders})}}
  const upstream=await fetch(new URL(path,process.env.YORUNGEZ_API_ORIGIN??'http://127.0.0.1:5187'),{method:request.method,headers,body,cache:'no-store',redirect:'error',signal:AbortSignal.timeout(15000)});
  const outgoing=new Headers(privateHeaders);
  for(const value of upstream.headers.getSetCookie())outgoing.append('Set-Cookie',value);
  return new Response(await upstream.text(),{status:upstream.status,headers:outgoing});
 }catch{return Response.json({code:'Common.Unavailable'},{status:503,headers:privateHeaders})}
}
