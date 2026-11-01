/// <reference lib="webworker" />
import { buildFrame } from "./frame.ts";
import type { SkyCatalog, ObserverContext } from "./types.ts";
let catalog: SkyCatalog | null = null;
self.onmessage = (event: MessageEvent<{ type: string; catalog?: SkyCatalog; context?: ObserverContext; sequence: number }>) => {
  if (event.data.type === "init") { catalog = event.data.catalog!; self.postMessage({ type: "ready" }); return; }
  if (!catalog || !event.data.context) return;
  try {
    const frame = buildFrame(catalog, event.data.context, event.data.sequence);
    self.postMessage({ type: "frame", frame }, { transfer: [frame.angles.buffer, frame.vectors.buffer,
      frame.equatorialToEnu.buffer, frame.artVectors.buffer, frame.solarEquatorial.buffer] });
  } catch (error) {
    self.postMessage({ type: "error", sequence: event.data.sequence,
      code: error instanceof Error ? error.message : "calculation" });
  }
};
