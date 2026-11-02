import type { SkyCatalog } from "./types.ts";
import type {BilingualTerm} from '../glossary.ts';
export type {BilingualTerm} from '../glossary.ts';
export async function loadSkyCatalog(signal:AbortSignal,fetcher:typeof fetch=fetch,timeoutMs=10000):Promise<{catalog:SkyCatalog;glossary:BilingualTerm[]}> {
  const response=await fetcher("/pwa/catalog.json",{cache:"no-cache",signal:AbortSignal.any([signal,AbortSignal.timeout(timeoutMs)])});
  if(!response.ok)throw new Error("catalog-http");
  const snapshot=await response.json();
  if(!Array.isArray(snapshot.catalog?.stars)||!snapshot.catalog.stars.length||!Array.isArray(snapshot.catalog.constellations)
    ||!Array.isArray(snapshot.glossary)||!snapshot.glossary.every((t:BilingualTerm)=>t.translations?.tr?.definition&&t.translations?.en?.definition))throw new Error("catalog-schema");
  return snapshot;
}
