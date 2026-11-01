import {calendarMonth} from '../../../lib/server/planning-catalog.ts';
export const runtime='nodejs';
export function GET(request:Request){try{const u=new URL(request.url),data=calendarMonth(Number(u.searchParams.get('year')),Number(u.searchParams.get('month'))),etag=`"${data.provenance.sha256}-${data.year}-${data.month}"`,headers={'Cache-Control':'public, max-age=86400',ETag:etag};if(request.headers.get('If-None-Match')===etag)return new Response(null,{status:304,headers});return Response.json(data,{headers});}catch{return Response.json({code:'Calendar.InvalidMonth'},{status:400});}}
