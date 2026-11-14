import { readJson } from '../../../lib/http/read-json.ts';

export const runtime = 'nodejs';

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const year = Number(searchParams.get('year'));
  const month = Number(searchParams.get('month'));
  if (!Number.isInteger(year) || year < 2000 || year > 2035 ||
      !Number.isInteger(month) || month < 1 || month > 12)
    return Response.json({}, { status: 400 });
  return proxy(request, '/api/v1/sky/observing-events/' + year + '/' + month);
}

export async function POST(request: Request) {
  const headers = { 'Cache-Control': 'no-store', 'Content-Type': 'application/json' };
  if (request.headers.get('Sec-Fetch-Site') === 'cross-site')
    return Response.json({}, { status: 403, headers });

  let body: unknown;
  try {
    body = await readJson(request);
  } catch {
    return Response.json({}, { status: 400, headers });
  }

  return proxy(request, '/api/v1/sky/observing-opportunities', JSON.stringify(body));
}

async function proxy(request: Request, path: string, body?: string) {
  const headers = { 'Cache-Control': 'no-store', 'Content-Type': 'application/json' };
  const upstreamHeaders: Record<string, string> = { 'Content-Type': 'application/json' };
  const seen = request.headers.get('X-Forwarded-For')?.split(',').at(-1)?.trim();
  if (seen) upstreamHeaders['X-Forwarded-For'] = seen;
  const visitor = request.headers.get('CF-Connecting-IP')?.trim();
  if (visitor) upstreamHeaders['CF-Connecting-IP'] = visitor;
  try {
    const url = new URL(path, process.env.YORUNGEZ_API_ORIGIN ?? 'http://127.0.0.1:5187');
    const result = await fetch(url, {
      method: request.method, headers: upstreamHeaders, body,
      cache: 'no-store', redirect: 'error',
      signal: AbortSignal.any([request.signal, AbortSignal.timeout(12000)]),
    });
    return new Response(await result.text(), { status: result.status, headers });
  } catch {
    return Response.json({}, { status: 503, headers });
  }
}
