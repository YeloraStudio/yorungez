export function apiProxyHeaders(request: Request): Record<string, string> {
  const headers: Record<string, string> = {};
  // The API trusts this Web hop. Use the configured public scheme, never a client-supplied proto.
  if (process.env.YORUNGEZ_WEB_ORIGIN?.startsWith('https://')) headers['X-Forwarded-Proto'] = 'https';
  // The API accepts the visitor header only when the reverse proxy saw a Cloudflare edge.
  const seen = request.headers.get('X-Forwarded-For')?.split(',').at(-1)?.trim();
  if (seen) headers['X-Forwarded-For'] = seen;
  const visitor = request.headers.get('CF-Connecting-IP')?.trim();
  if (visitor) headers['CF-Connecting-IP'] = visitor;
  return headers;
}
