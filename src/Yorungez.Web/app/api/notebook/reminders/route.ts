import { accountProxy } from '../../../../lib/server/account-proxy.ts';

export const runtime = 'nodejs';

export function GET(request: Request) {
  return accountProxy(request, '/api/v1/notebook/reminders');
}

export function POST(request: Request) {
  return accountProxy(request, '/api/v1/notebook/reminders');
}
