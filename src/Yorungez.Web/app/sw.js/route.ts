import {offlineArtifact} from '../../lib/server/offline-pack.ts';
export const runtime='nodejs';
export const dynamic='force-dynamic';
export function GET(){return offlineArtifact('worker.js','application/javascript; charset=utf-8')}
