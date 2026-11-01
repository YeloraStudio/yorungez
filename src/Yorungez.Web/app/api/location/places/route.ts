import {searchPlaces,nearestPlace} from '../../../../lib/server/planning-catalog.ts';
import {readJson} from '../../../../lib/http/read-json.ts';
export const runtime='nodejs';
export async function POST(request:Request){const headers={'Cache-Control':'no-store'};try{const input=await readJson(request) as {query?:string;latitude?:number;longitude?:number};
 const places=typeof input.query==='string'?searchPlaces(input.query):[nearestPlace(input.latitude!,input.longitude!)].filter(Boolean);
 return Response.json({places,source:'GeoNames',license:'CC BY 4.0',sourceUrl:'https://www.geonames.org/',mode:typeof input.query==='string'?'search':'nearest-place-point'}, {headers});
 }catch{return Response.json({code:'Place.InvalidInput'},{status:400,headers});}}
