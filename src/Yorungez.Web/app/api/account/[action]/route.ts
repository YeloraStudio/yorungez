import {accountProxy} from '../../../../lib/server/account-proxy.ts';
export const runtime='nodejs';
const writes:Record<string,string>={profile:'/api/v1/auth/profile',login:'/api/v1/session/login',register:'/api/v1/auth/register',logout:'/api/v1/auth/logout',
 'confirm-email':'/api/v1/auth/confirm-email','resend-confirmation':'/api/v1/auth/resend-confirmation',
 'forgot-password':'/api/v1/auth/forgot-password','reset-password':'/api/v1/auth/reset-password'};
export async function POST(request:Request,{params}:{params:Promise<{action:string}>}){
 const {action}=await params;return Object.hasOwn(writes,action)?accountProxy(request,writes[action]):Response.json({code:'Common.NotFound'},{status:404});
}
export async function GET(request:Request,{params}:{params:Promise<{action:string}>}){
 const {action}=await params;return action==='me'?accountProxy(request,'/api/v1/auth/me'):Response.json({code:'Common.NotFound'},{status:404});
}
