import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import {languageFromCookie} from './lib/language-preference.ts';
export function proxy(request: NextRequest) {
 const response=NextResponse.redirect(new URL('/'+(languageFromCookie(request.headers.get('cookie')??'')??'en'),request.url));
 response.headers.set('Cache-Control','private, no-store');response.headers.set('Vary','Cookie');return response;
}
export const config = { matcher: ["/"] };
