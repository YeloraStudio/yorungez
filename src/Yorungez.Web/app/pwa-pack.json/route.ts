import {offlineArtifact} from '../../lib/server/offline-pack.ts';
export const runtime='nodejs';
export const dynamic='force-dynamic';
export function GET(){return offlineArtifact('pack.json','application/json')}
